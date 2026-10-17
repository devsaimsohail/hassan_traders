class Customer < ApplicationRecord
  BILLED = "0".freeze
  RECEIVED = "0".freeze
  OVERDUE = "0".freeze
  LAST_PAYMENT = "NULL::date".freeze
  BALANCE = "(customers.opening_balance + #{BILLED} - #{RECEIVED})".freeze
  WITH_BALANCES = <<~SQL.squish.freeze
    (SELECT customers.*,
      #{BILLED} AS billed,
      #{RECEIVED} AS received,
      #{BALANCE} AS balance,
      #{OVERDUE} AS overdue,
      #{LAST_PAYMENT} AS last_payment,
      CASE WHEN #{BALANCE} > customers.credit_limit THEN 'Yes' ELSE 'No' END AS over_limit
    FROM customers) AS customers
  SQL
  EDITABLE = %w[name city area phone credit_limit terms_days note].freeze

  belongs_to :company

  scope :with_balances, -> { from(WITH_BALANCES) }

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
