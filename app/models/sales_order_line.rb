class SalesOrderLine < ApplicationRecord
  belongs_to :sales_order
  belongs_to :item

  validates :qty, numericality: { greater_than: 0 }
  validates :rate, numericality: { greater_than_or_equal_to: 0 }
  validate :finished_goods_of_company

  before_validation -> { self.amount = (qty.to_d * rate.to_d).round if qty && rate }

  private
    def finished_goods_of_company
      return unless item

      errors.add(:item, "must be finished goods") unless item.product?
      errors.add(:item, "belongs to another company") if sales_order && item.company_id != sales_order.company_id
    end
end
