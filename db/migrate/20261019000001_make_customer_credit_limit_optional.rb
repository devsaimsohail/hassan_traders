class MakeCustomerCreditLimitOptional < ActiveRecord::Migration[8.1]
  # A blank credit limit means "no limit": the customer is never flagged over it.
  def change
    change_column_null :customers, :credit_limit, true
    change_column_default :customers, :credit_limit, from: 0, to: nil
  end
end
