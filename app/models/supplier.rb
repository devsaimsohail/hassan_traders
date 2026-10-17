class Supplier < ApplicationRecord
  belongs_to :company
  has_many :purchase_orders, dependent: :restrict_with_exception
  has_many :supplier_payments, dependent: :restrict_with_exception

  normalizes :name, with: ->(v) { v.strip.squeeze(" ") }

  validates :name, presence: true, uniqueness: { scope: :company_id, case_sensitive: false }
  validates :code, presence: true, uniqueness: { scope: :company_id }

  before_validation :assign_code, on: :create

  def to_pay
    received = purchase_orders.where(status: "received")
    received.sum(:total) - supplier_payments.where(purchase_order_id: received.select(:id)).sum(:amount)
  end

  private
    def assign_code
      return if code.present? || company.nil?

      last = company.suppliers.where("code ~ '^S[0-9]+$'").pluck(:code).map { |c| c[1..].to_i }.max || 0
      self.code = format("S%02d", last + 1)
    end
end
