class SupplierPayment < ApplicationRecord
  METHODS = {
    "cash" => "Cash", "bank_transfer" => "Bank Transfer", "cheque" => "Cheque", "jazzcash" => "JazzCash", "easypaisa" => "Easypaisa"
  }.freeze

  belongs_to :company
  belongs_to :supplier
  belongs_to :purchase_order, optional: true
  belongs_to :user

  validates :date, presence: true
  validates :amount, numericality: { only_integer: true, greater_than: 0 }
  validates :method, inclusion: { in: METHODS.keys, message: "must be chosen" }
  validates :ref, presence: { message: "is needed for %{value}" }, unless: -> { method == "cash" }

  def readonly? = persisted?
  def method_label = METHODS[method]
end
