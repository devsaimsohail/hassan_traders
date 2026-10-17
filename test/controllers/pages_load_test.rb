require "test_helper"

class PagesLoadTest < ActionDispatch::IntegrationTest
  test "every page opens for a partner" do
    sign_in_as users(:partner)
    paths = [
      root_path, settings_path, new_person_path, edit_password_path, activity_logs_path,
      items_path, new_item_path, item_path(items(:yarn)), edit_item_path(items(:yarn)),
      stock_moves_path, new_production_issue_path,
      purchase_orders_path, new_purchase_order_path, suppliers_path, new_supplier_path, edit_supplier_path(suppliers(:kohinoor)),
      customers_path, new_customer_path, customer_path(customers(:khan)), edit_customer_path(customers(:khan))
    ]
    po = companies(:hassan).purchase_orders.create!(supplier: suppliers(:kohinoor), date: Date.current, created_by: users(:partner),
      lines_attributes: [ { item_id: items(:yarn).id, qty: 1, rate: 1 } ])
    paths += [ purchase_order_path(po), edit_purchase_order_path(po), copy_purchase_order_path(po) ]

    paths.each do |path|
      get path
      assert_response :success, "#{path} did not open"
    end
  end
end
