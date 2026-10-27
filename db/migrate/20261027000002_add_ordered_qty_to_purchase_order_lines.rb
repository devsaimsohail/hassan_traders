class AddOrderedQtyToPurchaseOrderLines < ActiveRecord::Migration[8.1]
  # Set on receiving when the godown got a different quantity than ordered; qty then holds what came.
  def change
    add_column :purchase_order_lines, :ordered_qty, :decimal, precision: 12, scale: 3
  end
end
