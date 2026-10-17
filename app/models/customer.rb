class Customer < ApplicationRecord
  RECEIVED = "0".freeze
  LAST_PAYMENT = "NULL::date".freeze
  EDITABLE = %w[name city area phone credit_limit terms_days note].freeze

  belongs_to :company
  has_many :sales_orders, dependent: :restrict_with_exception
  has_many :invoices, dependent: :restrict_with_exception

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

  validates :name, presence: true, uniqueness: { scope: :company_id, case_sensitive: false }
  validates :code, presence: true, uniqueness: { scope: :company_id }
  validates :credit_limit, :terms_days, :opening_balance, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :assign_code, on: :create

  def place = [ area, city ].compact_blank.join(", ")

  private
    def assign_code
      return if code.present? || company.nil?

      last = company.customers.where("code ~ '^C[0-9]+$'").pluck(:code).map { |c| c[1..].to_i }.max || 0
      self.code = format("C%02d", last + 1)
    end
end
