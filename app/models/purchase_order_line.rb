class PurchaseOrderLine < ApplicationRecord
  belongs_to :purchase_order
  belongs_to :item

  validates :qty, numericality: { greater_than: 0 }
  validates :rate, numericality: { greater_than_or_equal_to: 0 }
  validate :item_in_company

  before_validation -> { self.amount = (qty.to_d * rate.to_d).round if qty && rate }

  private
    def item_in_company
      errors.add(:item, "belongs to another company") if item && purchase_order && item.company_id != purchase_order.company_id
    end
end
