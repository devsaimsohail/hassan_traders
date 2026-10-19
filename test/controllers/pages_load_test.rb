require "test_helper"

class PagesLoadTest < ActionDispatch::IntegrationTest
  test "every page opens for a partner" do
    sign_in_as users(:partner)
    paths = [
      root_path, settings_path, new_person_path, edit_password_path, activity_logs_path,
      items_path, new_item_path, item_path(items(:yarn)), edit_item_path(items(:yarn)),
      stock_moves_path, new_production_issue_path, units_path, new_unit_path, edit_unit_path(units(:kg)),
      purchase_orders_path, new_purchase_order_path, suppliers_path, new_supplier_path, edit_supplier_path(suppliers(:kohinoor)),
      customers_path, new_customer_path, customer_path(customers(:khan)), edit_customer_path(customers(:khan)),
      sales_orders_path, new_sales_order_path, invoices_path, payments_path, new_payment_path, khata_path
    ]
    po = companies(:hassan).purchase_orders.create!(supplier: suppliers(:kohinoor), date: Date.current, created_by: users(:partner),
      lines_attributes: [ { item_id: items(:yarn).id, qty: 1, rate: 1 } ])
    paths += [ purchase_order_path(po), edit_purchase_order_path(po), copy_purchase_order_path(po) ]
    so = companies(:hassan).sales_orders.create!(customer: customers(:khan), date: Date.current, booked_by: users(:partner),
      lines_attributes: [ { item_id: items(:suit).id, qty: 1, rate: 3400 } ])
    paths << sales_order_path(so)
    bill = so.dispatch!(by: users(:partner))
    paths << invoice_path(bill)
    pay = Payment.receive!(company: companies(:hassan), by: users(:partner), customer: customers(:khan), invoice: bill, amount: 100, method: "cash", date: Date.current)
    paths += [ payment_path(pay), new_payment_path(invoice_id: bill.id), customer_path(customers(:khan)) ]

    paths.each do |path|
      get path
      assert_response :success, "#{path} did not open"
    end
  end
end
