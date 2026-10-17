require "test_helper"

class PurchaseOrdersControllerTest < ActionDispatch::IntegrationTest
  def po_params(**extra)
    { purchase_order: { supplier_id: suppliers(:kohinoor).id, date: "2026-10-18", lines_attributes: { "0" => { item_id: items(:yarn).id, qty: "100", rate: "12" } } } }.merge(extra)
  end

  test "an accountant sends a PO for approval" do
    sign_in_as users(:accountant)
    post purchase_orders_path, params: po_params(send: "1")

    po = PurchaseOrder.last
    assert_redirected_to purchase_order_path(po)
    assert po.pending_approval?
    assert_equal 1200, po.total
  end

  test "saving as a draft keeps it a draft" do
    sign_in_as users(:accountant)
    post purchase_orders_path, params: po_params

    assert PurchaseOrder.last.draft?
    assert_equal "Saved draft PO for Kohinoor Yarn Traders — Rs 1,200", ActivityLog.order(:id).last.detail
  end

  test "the full flow: partner approves, store receives, accountant pays" do
    items(:yarn).update!(last_purchase_rate: 10)
    sign_in_as users(:accountant)
    post purchase_orders_path, params: po_params(send: "1")
    po = PurchaseOrder.last

    post approve_purchase_order_path(po)
    assert_response :forbidden

    sign_in_as users(:partner)
    post approve_purchase_order_path(po)
    assert po.reload.approved?

    sign_in_as users(:store)
    post receive_purchase_order_path(po), params: { received_on: "2026-10-18" }
    assert_redirected_to purchase_order_path(po)
    follow_redirect!
    assert_select "#price-changes", text: /Cotton Yarn 20s: Rs 10 → Rs 12\s+\(\+20%\)/
    assert_equal 2500, items(:yarn).current_stock

    sign_in_as users(:accountant)
    post pay_purchase_order_path(po), params: { payment: { amount: "1200", method: "bank_transfer", ref: "IBFT 123", date: "2026-10-18" } }
    assert_equal "Paid", po.reload.pay_status
  end

  test "store staff can't make POs and sales staff can't see them" do
    sign_in_as users(:store)
    get new_purchase_order_path
    assert_response :forbidden

    sign_in_as users(:sales)
    get purchase_orders_path
    assert_response :forbidden
  end

  test "new PO for an item fills in the item, its rate and usual supplier" do
    items(:yarn).update!(default_supplier: suppliers(:kohinoor), last_purchase_rate: 735)
    sign_in_as users(:partner)
    get new_purchase_order_path(item_id: items(:yarn).id)

    assert_select "select[name='purchase_order[supplier_id]'] option[selected][value='#{suppliers(:kohinoor).id}']"
    assert_select "input[name='purchase_order[lines_attributes][0][rate]'][value='735']"
  end

  test "partners cancel with a reason; drafts can be deleted" do
    sign_in_as users(:partner)
    post purchase_orders_path, params: po_params
    po = PurchaseOrder.last

    post cancel_purchase_order_path(po), params: { reason: "Rate too high" }
    assert po.reload.cancelled?

    post purchase_orders_path, params: po_params
    draft = PurchaseOrder.last
    delete purchase_order_path(draft)
    assert_not PurchaseOrder.exists?(draft.id)
  end

  test "PDFs for the list and one PO" do
    sign_in_as users(:partner)
    post purchase_orders_path, params: po_params(send: "1")

    get purchase_order_path(PurchaseOrder.last, format: :pdf)
    assert_equal "application/pdf", response.media_type

    get purchase_orders_path(format: :pdf, tab: "draft")
    assert_match "purchase-orders-date-all-dates-show-draft.pdf", response.headers["Content-Disposition"]
  end

  test "a stock move against a PO links to it" do
    sign_in_as users(:partner)
    post purchase_orders_path, params: po_params(send: "1")
    po = PurchaseOrder.last
    po.receive!(by: users(:store))

    get stock_moves_path
    assert_select "tr[data-row-link-href-value='#{purchase_order_path(po)}']"
  end
end
