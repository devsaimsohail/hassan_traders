require "test_helper"

class SalesOrdersControllerTest < ActionDispatch::IntegrationTest
  def order_params(qty: "80")
    { sales_order: { customer_id: customers(:khan).id, date: "2026-10-18", lines_attributes: { "0" => { item_id: items(:suit).id, qty:, rate: "3400" } } } }
  end

  test "a sales officer books, the store dispatches, a bill is made" do
    sign_in_as users(:sales)
    post sales_orders_path, params: order_params
    so = SalesOrder.last
    assert_redirected_to sales_order_path(so)
    assert_equal [ "SO-3001", 272_000, "Order from Khan Brothers — Rs 2,72,000" ], [ so.number, so.amount, ActivityLog.order(:id).last.detail ]

    post dispatch_goods_sales_order_path(so)
    assert_response :forbidden

    sign_in_as users(:store)
    post dispatch_goods_sales_order_path(so), params: { dispatched_on: "2026-10-18" }
    assert_redirected_to sales_order_path(so)
    assert so.reload.dispatched?
    assert so.invoice

    post deliver_sales_order_path(so)
    assert so.reload.delivered?
  end

  test "booking past the credit limit shows a warning" do
    sign_in_as users(:partner)
    post sales_orders_path, params: order_params(qty: "400")

    assert_match "over their credit limit", flash[:alert]
  end

  test "a short dispatch is explained" do
    sign_in_as users(:partner)
    post sales_orders_path, params: order_params(qty: "950")
    so = SalesOrder.last
    post dispatch_goods_sales_order_path(so)

    assert_equal "Only 900 suit of Lawn Suit 3-Piece in stock", flash[:alert]
  end

  test "only a partner cancels, and accountants only view" do
    sign_in_as users(:sales)
    post sales_orders_path, params: order_params
    so = SalesOrder.last

    post cancel_sales_order_path(so), params: { reason: "x" }
    assert_response :forbidden

    sign_in_as users(:accountant)
    get sales_orders_path
    assert_response :success
    post sales_orders_path, params: order_params
    assert_response :forbidden

    sign_in_as users(:partner)
    post cancel_sales_order_path(so), params: { reason: "Cancelled by customer" }
    assert so.reload.cancelled?
  end

  test "list tabs and PDFs" do
    sign_in_as users(:partner)
    post sales_orders_path, params: order_params
    so = SalesOrder.last

    get sales_orders_path(tab: "pending")
    assert_select "tbody tr", 1
    get sales_order_path(so, format: :pdf)
    assert_equal "application/pdf", response.media_type
    get sales_orders_path(format: :pdf, tab: "pending")
    assert_match "sales-orders-date-all-dates-status-pending.pdf", response.headers["Content-Disposition"]
  end
end
