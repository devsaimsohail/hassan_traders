class PurchaseOrder < ApplicationRecord
  class NotAllowed < StandardError; end

  STATUSES = %w[draft pending_approval approved received cancelled].freeze
  OPEN = %w[draft pending_approval approved].freeze

  PriceChange = Data.define(:item, :old_rate, :new_rate, :avg_cost) do
    def percent = old_rate.to_d.zero? ? nil : ((new_rate - old_rate) / old_rate * 100).round(1)
  end

  belongs_to :company
  belongs_to :supplier
  belongs_to :created_by, class_name: "User"
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :received_by, class_name: "User", optional: true
  belongs_to :cancelled_by, class_name: "User", optional: true
  has_many :lines, -> { order(:id) }, class_name: "PurchaseOrderLine", dependent: :destroy, inverse_of: :purchase_order
  has_many :supplier_payments, dependent: :restrict_with_exception

  accepts_nested_attributes_for :lines, allow_destroy: true, reject_if: ->(a) { a[:item_id].blank? && a[:qty].blank? }

  validates :date, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :has_lines
  validate :supplier_in_company

  before_validation :assign_number, on: :create
  before_save -> { self.total = lines.reject(&:marked_for_destruction?).sum { |l| (l.qty.to_d * l.rate.to_d).round } }

  STATUSES.each { |s| define_method("#{s}?") { status == s } }

  def paid = supplier_payments.sum(:amount)
  def balance = received? ? total - paid : 0

  def pay_status
    return "Not due" unless received?
    return "Paid" if balance <= 0

    paid.positive? ? "Partly paid" : "Unpaid"
  end

  def items_summary
    lines.map { |l| "#{l.item.name} × #{Fmt.qty(l.qty)} #{l.item.unit}" }.join(", ")
  end

  def submit!(by:)
    raise NotAllowed, "Only drafts can be sent" unless draft?

    can_approve = Access.new(by, company).can?(:purchase_approve)
    transaction do
      if can_approve
        update!(status: "approved", approved_by: by, approved_at: Time.current)
      else
        update!(status: "pending_approval")
      end
      log!(by, "Created", "New PO for #{supplier.name} — #{Fmt.rs(total)}")
      log!(by, "Approved", "Approved PO — #{Fmt.rs(total)}") if can_approve
    end
  end

  def approve!(by:)
    raise NotAllowed, "This PO is not waiting for approval" unless pending_approval?

    transaction do
      update!(status: "approved", approved_by: by, approved_at: Time.current)
      log!(by, "Approved", "Approved PO — #{Fmt.rs(total)}")
    end
  end

  def receive!(by:, on: Date.current)
    raise NotAllowed, "Only approved POs can be received" unless approved?

    transaction do
      items = company.items.where(id: lines.map(&:item_id)).order(:id).lock.index_by(&:id)
      changes = lines.map do |line|
        item = items.fetch(line.item_id)
        stock_before = item.current_stock
        old_rate = item.last_purchase_rate || item.rate
        avg = stock_before.positive? ? ((stock_before * item.rate + line.qty * line.rate) / (stock_before + line.qty)).round(2) : line.rate
        company.stock_moves.create!(item:, user: by, date: on, direction: "in", reason: "purchase_receive", qty: line.qty, ref: number)
        item.update!(rate: avg, last_purchase_rate: line.rate, last_purchase_on: on, default_supplier: supplier)
        log!(by, "Received", "Received #{Fmt.qty(line.qty)} #{item.unit} #{item.name} — stock updated", section: "Stock")
        PriceChange.new(item:, old_rate:, new_rate: line.rate, avg_cost: avg)
      end
      update!(status: "received", received_by: by, received_on: on)
      changes.select { |c| c.new_rate > c.old_rate && c.old_rate.positive? }
    end
  end

  def pay!(by:, amount:, method:, ref: nil, date: Date.current)
    raise NotAllowed, "Goods must be received before paying" unless received?

    payment = supplier_payments.new(company:, supplier:, user: by, amount:, method:, ref: ref.presence, date:)
    payment.validate
    payment.errors.add(:amount, "can't be more than #{Fmt.rs(balance)} still to pay") if payment.amount.to_i > balance
    return payment if payment.errors.any?

    transaction do
      payment.save!
      log!(by, "Paid", "Paid #{Fmt.rs(payment.amount)} #{payment.method_label} to #{supplier.name}", section: "Payments")
    end
    payment
  end

  def cancel!(by:, reason:)
    raise NotAllowed, "This PO can't be cancelled" unless OPEN.include?(status)
    raise NotAllowed, "Please give a reason" if reason.blank?

    transaction do
      update!(status: "cancelled", cancelled_by: by, cancelled_at: Time.current, cancel_reason: reason)
      log!(by, "Cancelled", "PO cancelled — #{reason}")
    end
  end

  def discard!(by:)
    raise NotAllowed, "Only drafts can be deleted" unless draft?

    transaction do
      log!(by, "Deleted", "Deleted draft PO for #{supplier.name} (never sent)")
      destroy!
    end
  end

  def copy_for(by)
    company.purchase_orders.new(supplier:, date: Date.current, created_by: by, note:).tap do |po|
      lines.each { |l| po.lines.build(item: l.item, qty: l.qty, rate: l.item.last_purchase_rate || l.item.rate) }
    end
  end

  def log!(by, action, detail, section: "Purchase")
    ActivityLog.record!(company:, user: by, action:, section:, ref: number, detail:)
  end

  private
    def assign_number
      return if number.present? || company.nil?

      last = company.purchase_orders.where("number ~ '^PO-[0-9]+$'").pluck(:number).map { |n| n.delete_prefix("PO-").to_i }.max
      self.number = "PO-#{(last || 1000) + 1}"
    end

    def has_lines
      errors.add(:base, "Add at least one item with a quantity") if lines.reject(&:marked_for_destruction?).empty?
    end

    def supplier_in_company
      errors.add(:supplier, "must be chosen") if supplier.nil? || supplier.company_id != company_id
    end
end
