class Payment < ApplicationRecord
  class NotAllowed < StandardError; end

  METHODS = SupplierPayment::METHODS
  AGAINST = { "bill" => "Bill", "opening_balance" => "Opening balance", "on_account" => "On account" }.freeze
  LIVE_SQL = "payments.reversed_at IS NULL".freeze

  belongs_to :company
  belongs_to :customer
  belongs_to :invoice, optional: true
  belongs_to :received_by, class_name: "User"
  belongs_to :reversed_by, class_name: "User", optional: true

  scope :live, -> { where(reversed_at: nil) }

  validates :date, presence: true
  validates :amount, numericality: { only_integer: true, greater_than: 0 }
  validates :method, inclusion: { in: METHODS.keys, message: "must be chosen" }
  validates :against, inclusion: { in: AGAINST.keys }
  validates :ref, presence: { message: "is needed for a cheque, bank transfer or wallet payment" }, unless: -> { method == "cash" }
  validate :invoice_matches
  validate :not_more_than_due, on: :create

  before_validation :assign_number, on: :create
  before_validation -> { self.against = "bill" if invoice_id.present? }

  def self.receive!(company:, by:, **attributes)
    payment = company.payments.new(received_by: by, **attributes)
    transaction do
      payment.invoice&.lock!
      payment.customer&.lock!
      if payment.save
        ActivityLog.record!(company:, user: by, action: "Payment received", section: "Payments", ref: payment.number,
          detail: "#{Fmt.rs(payment.amount)} #{payment.method_label} from #{payment.customer.name} against #{payment.against_label}")
      end
    end
    payment
  end

  def reversed? = reversed_at.present?
  def method_label = METHODS[method]
  def against_label = invoice ? invoice.number : AGAINST[against]

  def reverse!(by:, reason:)
    raise NotAllowed, "This receipt is already reversed" if reversed?
    raise NotAllowed, "Please give a reason, e.g. cheque bounced" if reason.blank?

    transaction do
      update!(reversed_at: Time.current, reversed_by: by, reverse_reason: reason)
      ActivityLog.record!(company:, user: by, action: "Reversed", section: "Payments", ref: number,
        detail: "Reversed #{Fmt.rs(amount)} from #{customer.name} — #{reason}")
    end
  end

  def opening_left
    customer.opening_balance - customer.payments.live.where(against: "opening_balance").where.not(id: id).sum(:amount)
  end

  private
    def assign_number
      return if number.present? || company.nil?

      last = company.payments.where("number ~ '^RV-[0-9]+$'").pluck(:number).map { |n| n.delete_prefix("RV-").to_i }.max
      self.number = "RV-#{(last || 5000) + 1}"
    end

    def invoice_matches
      errors.add(:customer, "must be chosen") if customer.nil? || customer.company_id != company_id
      return unless invoice

      errors.add(:invoice, "belongs to another customer") if invoice.customer_id != customer_id
      errors.add(:invoice, "is cancelled") if invoice.cancelled?
    end

    def not_more_than_due
      return unless amount.to_i.positive? && customer

      due =
        case against
        when "bill" then invoice && Invoice.with_status.find(invoice.id).balance
        when "opening_balance" then opening_left
        end
      errors.add(:amount, "can't be more than #{Fmt.rs(due)} still due on #{against_label}") if due && amount > due
    end
end
