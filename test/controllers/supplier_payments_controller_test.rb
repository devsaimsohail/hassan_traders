require "test_helper"

class SupplierPaymentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @po = companies(:hassan).purchase_orders.create!(supplier: suppliers(:kohinoor), date: Date.current, created_by: users(:partner),
      lines_attributes: [ { item_id: items(:yarn).id, qty: 100, rate: 10 } ])
    @po.submit!(by: users(:partner))
    @po.receive!(by: users(:store))
    @po.pay!(by: users(:accountant), amount: 400, method: "cheque", ref: "Chq 1122", note: "Advance against yarn")
  end

  test "the supplier khata tab lists payments and opens their PO" do
    sign_in_as users(:partner)
    get supplier_payments_path(supplier: "Kohinoor Yarn Traders")

    assert_select "nav[aria-label='Purchase pages'] a[aria-current='page']", text: "Supplier khata"
    assert_select "td", text: "Advance against yarn"
    assert_select "tr[data-row-link-href-value='#{purchase_order_path(@po)}']"
  end

  test "the PDF download is logged with its filters" do
    sign_in_as users(:accountant)
    get supplier_payments_path(format: :pdf, tab: "cheque")

    assert_equal "application/pdf", response.media_type
    assert_equal "Downloaded Supplier payments (Date: All dates, Method: Cheque)", ActivityLog.order(:id).last.detail
  end

  test "store staff can view, sales staff can't" do
    sign_in_as users(:store)
    get supplier_payments_path
    assert_response :success

    sign_in_as users(:sales)
    get supplier_payments_path
    assert_response :forbidden
  end
end
