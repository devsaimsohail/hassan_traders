class Customer < ApplicationRecord
  RECEIVED = "COALESCE((SELECT SUM(p.amount) FROM payments p WHERE p.customer_id = customers.id AND p.reversed_at IS NULL), 0)".freeze
  LAST_PAYMENT = "(SELECT MAX(p.date) FROM payments p WHERE p.customer_id = customers.id AND p.reversed_at IS NULL)".freeze
  EDITABLE = %w[name city area phone credit_limit terms_days note].freeze
  DEFAULT_TERMS_DAYS = 30

  belongs_to :company
  has_many :sales_orders, dependent: :restrict_with_exception
  has_many :invoices, dependent: :restrict_with_exception
  has_many :payments, dependent: :restrict_with_exception

  scope :with_balances, ->(on = Date.current) { from("#{balances_sql(on)} AS customers") }

  def self.balances_sql(on)
    balance = "(customers.opening_balance + COALESCE(b.billed, 0) - #{RECEIVED})"
    <<~SQL.squish
      (SELECT customers.*,
        COALESCE(b.billed, 0) AS billed,
        #{RECEIVED} AS received,
        #{balance} AS balance,
        COALESCE(b.overdue, 0) AS overdue,
        #{LAST_PAYMENT} AS last_payment,
        CASE WHEN #{balance} > customers.credit_limit THEN 'Yes' ELSE 'No' END AS over_limit
      FROM customers
      LEFT JOIN (
        SELECT customer_id, SUM(amount) AS billed, SUM(balance) FILTER (WHERE status = 'Overdue') AS overdue
        FROM #{Invoice.status_table_sql(on)} AS bills
        WHERE cancelled_at IS NULL GROUP BY customer_id
      ) b ON b.customer_id = customers.id)
    SQL
  end

  normalizes :name, :city, :area, with: ->(v) { v.strip.squeeze(" ").presence }
  normalizes :phone, with: ->(v) { v.strip.presence }
  normalizes :note, with: ->(v) { v.strip.presence }

  validates :name, presence: true, uniqueness: { scope: :company_id, case_sensitive: false }
  validates :code, presence: true, uniqueness: { scope: :company_id }
  validates :terms_days, :opening_balance, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :credit_limit, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  before_validation :assign_code, on: :create
  before_validation :fill_blank_defaults

  def self.limit_text(amount) = amount.nil? ? "No limit" : Fmt.rs(amount)

  def place = [ area, city ].compact_blank.join(", ")

  private
    # Only the name is required. Blank terms mean 30 days and a blank opening balance means 0.
    # A blank credit limit stays nil and means "no limit".
    def fill_blank_defaults
      self.terms_days ||= DEFAULT_TERMS_DAYS
      self.opening_balance ||= 0
    end

    def assign_code
      return if code.present? || company.nil?

      last = company.customers.where("code ~ '^C[0-9]+$'").pluck(:code).map { |c| c[1..].to_i }.max || 0
      self.code = format("C%02d", last + 1)
    end
end
