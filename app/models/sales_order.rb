class SalesOrder < ApplicationRecord
  class NotAllowed < StandardError; end

  STATUSES = %w[pending dispatched delivered cancelled].freeze
  STATUS_LABELS = STATUSES.index_with(&:capitalize).freeze

  belongs_to :company
  belongs_to :customer
  belongs_to :booked_by, class_name: "User"
  belongs_to :dispatched_by, class_name: "User", optional: true
  belongs_to :delivered_by, class_name: "User", optional: true
  belongs_to :cancelled_by, class_name: "User", optional: true
  has_many :lines, -> { order(:id) }, class_name: "SalesOrderLine", dependent: :destroy, inverse_of: :sales_order
  has_one :invoice, dependent: :restrict_with_exception

  accepts_nested_attributes_for :lines, reject_if: ->(a) { a[:item_id].blank? && a[:qty].blank? }

  validates :date, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :has_lines
  validate :customer_in_company

  before_validation :assign_number, on: :create
  before_save -> { self.amount = lines.sum { |l| (l.qty.to_d * l.rate.to_d).round } }

  STATUSES.each { |s| define_method("#{s}?") { status == s } }

  def status_label = STATUS_LABELS[status]

  def items_summary
    lines.map { |l| "#{l.item.name} × #{Fmt.qty(l.qty)}" }.join(", ")
  end

  def credit_warning
    current = Customer.with_balances.find(customer_id)
    after = current.balance + amount
    return "#{customer.name} is already over their credit limit of #{Fmt.rs(customer.credit_limit)}." if current.balance > customer.credit_limit
    "This order takes #{customer.name} to #{Fmt.rs(after)}, over their credit limit of #{Fmt.rs(customer.credit_limit)}." if after > customer.credit_limit
  end

  def book!(by:)
    log!(by, "Created", "Order from #{customer.name} — #{Fmt.rs(amount)}")
  end

  def dispatch!(by:, on: Date.current)
    raise NotAllowed, "Only pending orders can be dispatched" unless pending?

    transaction do
      items = company.items.where(id: lines.map(&:item_id)).order(:id).lock.index_by(&:id)
      needed = lines.group_by(&:item_id).transform_values { |ls| ls.sum(&:qty) }
      short = needed.filter_map do |id, qty|
        item = items.fetch(id)
        "Only #{Fmt.qty(item.current_stock)} #{item.unit} of #{item.name} in stock" if item.current_stock < qty
      end
      raise NotAllowed, short.to_sentence if short.any?

      lines.each do |line|
        company.stock_moves.create!(item: items.fetch(line.item_id), user: by, date: on, direction: "out", reason: "sale_dispatch", qty: line.qty, ref: number)
      end
      update!(status: "dispatched", dispatched_by: by, dispatched_on: on)
      log!(by, "Dispatched", "Dispatched to #{customer.name}#{" (#{customer.city})" if customer.city}", section: "Stock")
      Invoice.create_for!(self, by:, on:)
    end
  end

  def deliver!(by:, on: Date.current)
    raise NotAllowed, "Only dispatched orders can be marked delivered" unless dispatched?

    transaction do
      update!(status: "delivered", delivered_by: by, delivered_on: on)
      log!(by, "Edited", "Marked delivered to #{customer.name}")
    end
  end

  def cancel!(by:, reason:)
    raise NotAllowed, "Only pending orders can be cancelled" unless pending?
    raise NotAllowed, "Please give a reason" if reason.blank?

    transaction do
      update!(status: "cancelled", cancelled_by: by, cancelled_at: Time.current, cancel_reason: reason)
      log!(by, "Cancelled", "Order cancelled — #{reason}")
    end
  end

  def log!(by, action, detail, section: "Sales")
    ActivityLog.record!(company:, user: by, action:, section:, ref: number, detail:)
  end

  private
    def assign_number
      return if number.present? || company.nil?

      last = company.sales_orders.where("number ~ '^SO-[0-9]+$'").pluck(:number).map { |n| n.delete_prefix("SO-").to_i }.max
      self.number = "SO-#{(last || 3000) + 1}"
    end

    def has_lines
      errors.add(:base, "Add at least one item with a quantity") if lines.empty?
    end

    def customer_in_company
      errors.add(:customer, "must be chosen") if customer.nil? || customer.company_id != company_id
    end
end
