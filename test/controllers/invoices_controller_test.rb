require "test_helper"

class InvoicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    so = companies(:hassan).sales_orders.create!(customer: customers(:khan), date: 60.days.ago.to_date, booked_by: users(:sales),
      lines_attributes: [ { item_id: items(:suit).id, qty: 10, rate: 3400 } ])
    @invoice = so.dispatch!(by: users(:store), on: 60.days.ago.to_date)
  end

  test "the bills list shows overdue bills in the Overdue tab" do
    sign_in_as users(:accountant)
    get invoices_path(tab: "overdue")

    assert_response :success
    assert_select "td", text: @invoice.number
    assert_select "td", text: "Rs 34,000"
  end

  test "the bill page, PDF and customer page" do
    sign_in_as users(:partner)
    get invoice_path(@invoice)
    assert_response :success
    assert_select "span", text: "Overdue"

    get invoice_path(@invoice, format: :pdf)
    assert_equal "application/pdf", response.media_type
    assert_equal "Downloaded bill #{@invoice.number} for Khan Brothers", ActivityLog.order(:id).last.detail

    get customer_path(customers(:khan))
    assert_select "#unpaid-bills td", text: @invoice.number
    assert_select "#latest-orders td", text: @invoice.sales_order.number
  end

  test "partners extend the due date or cancel; staff can't" do
    sign_in_as users(:accountant)
    post cancel_invoice_path(@invoice), params: { reason: "x" }
    assert_response :forbidden

    sign_in_as users(:partner)
    post extend_due_invoice_path(@invoice), params: { due_date: (Date.current + 10).iso8601 }
    assert_equal Date.current + 10, @invoice.reload.due_date

    post cancel_invoice_path(@invoice), params: { reason: "Wrong customer" }
    assert @invoice.reload.cancelled?
  end

  test "store staff can't see bills" do
    sign_in_as users(:store)
    get invoices_path
    assert_response :forbidden
  end
end
