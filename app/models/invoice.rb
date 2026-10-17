class Invoice < ApplicationRecord
  class NotAllowed < StandardError; end

  RECEIVED = "0".freeze
  STATUSES = %w[Unpaid Partial Overdue Paid Cancelled].freeze

  belongs_to :company
  belongs_to :customer
  belongs_to :sales_order, optional: true
  belongs_to :created_by, class_name: "User"
  belongs_to :cancelled_by, class_name: "User", optional: true
  has_many :lines, -> { order(:id) }, class_name: "InvoiceLine", dependent: :destroy

  validates :number, :date, :due_date, presence: true

  scope :with_status, ->(on = Date.current) { from("#{status_table_sql(on)} AS invoices") }
  scope :live, -> { where(cancelled_at: nil) }

  def self.status_table_sql(on)
    day = "#{connection.quote(on.to_date)}::date"
    <<~SQL.squish
      (SELECT invoices.*,
        #{RECEIVED} AS received,
        invoices.amount - #{RECEIVED} AS balance,
        CASE WHEN invoices.cancelled_at IS NOT NULL THEN 'Cancelled'
             WHEN invoices.amount - #{RECEIVED} <= 0 THEN 'Paid'
             WHEN invoices.due_date < #{day} THEN 'Overdue'
             WHEN #{RECEIVED} > 0 THEN 'Partial'
             ELSE 'Unpaid' END AS status,
        CASE WHEN invoices.cancelled_at IS NULL AND invoices.amount - #{RECEIVED} > 0 AND invoices.due_date < #{day}
             THEN #{day} - invoices.due_date ELSE 0 END AS days_overdue
      FROM invoices)
    SQL
  end

  def self.create_for!(order, by:, on:)
    invoice = order.company.invoices.new(customer: order.customer, sales_order: order, date: on,
      due_date: on + order.customer.terms_days.days, amount: order.amount, created_by: by)
    invoice.number = next_number(order.company)
    order.lines.each { |l| invoice.lines.build(item: l.item, qty: l.qty, rate: l.rate, amount: l.amount) }
    invoice.save!
    ActivityLog.record!(company: order.company, user: by, action: "Created", section: "Invoices", ref: invoice.number,
      detail: "Bill to #{order.customer.name} — #{Fmt.rs(invoice.amount)}")
    invoice
  end

  def self.next_number(company)
    last = company.invoices.where("number ~ '^INV-[0-9]+$'").pluck(:number).map { |n| n.delete_prefix("INV-").to_i }.max
    "INV-#{(last || 2000) + 1}"
  end

  def cancelled? = cancelled_at.present?

  def status_now
    has_attribute?(:status) ? self[:status] : Invoice.with_status.find(id).status
  end

  def extend_due!(by:, to:)
    raise NotAllowed, "This bill is cancelled" if cancelled?
    raise NotAllowed, "Choose a date after #{Fmt.date(due_date)}" if to.nil? || to <= due_date

    old = due_date
    transaction do
      update!(due_date: to)
      ActivityLog.record!(company:, user: by, action: "Edited", section: "Invoices", ref: number,
        detail: "Due date moved from #{Fmt.date(old)} to #{Fmt.date(to)} (#{(to - old).to_i} days)",
        old_value: { "due_date" => old }, new_value: { "due_date" => to })
    end
  end

  def cancel!(by:, reason:)
    raise NotAllowed, "This bill is already cancelled" if cancelled?
    raise NotAllowed, "Please give a reason" if reason.blank?

    transaction do
      update!(cancelled_by: by, cancelled_at: Time.current, cancel_reason: reason)
      ActivityLog.record!(company:, user: by, action: "Cancelled", section: "Invoices", ref: number,
        detail: "Bill cancelled — #{reason}. #{Fmt.rs(amount)} removed from #{customer.name}'s udhaar")
    end
  end
end
