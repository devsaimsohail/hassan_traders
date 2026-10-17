require "test_helper"

class PaymentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    so = companies(:hassan).sales_orders.create!(customer: customers(:khan), date: Date.current, booked_by: users(:sales),
      lines_attributes: [ { item_id: items(:suit).id, qty: 10, rate: 3400 } ])
    @bill = so.dispatch!(by: users(:store))
  end

  test "an accountant receives a payment against a bill" do
    sign_in_as users(:accountant)
    get new_payment_path(invoice_id: @bill.id)
    assert_select "input[name='payment[amount]'][value='34000']"
    assert_select "option[selected][value='invoice:#{@bill.id}']"

    post payments_path, params: { payment: { customer_id: customers(:khan).id, against_choice: "invoice:#{@bill.id}", amount: "34000", method: "bank_transfer", ref: "IBFT 991", date: Date.current.iso8601 } }

    pay = Payment.last
    assert_redirected_to payment_path(pay)
    assert_equal [ @bill, 34_000, "Paid" ], [ pay.invoice, pay.amount, Invoice.with_status.find(@bill.id).status ]
  end

  test "each customer has their own opening balance choice" do
    sign_in_as users(:accountant)
    get new_payment_path(customer_id: customers(:haq).id)

    assert_select "option[value='opening_balance:#{customers(:haq).id}'][data-due='340000']"
    assert_select "option[value='opening_balance:#{customers(:khan).id}'][data-due='520000']"

    post payments_path, params: { payment: { customer_id: customers(:haq).id, against_choice: "opening_balance:#{customers(:haq).id}", amount: "40000", method: "cash", date: Date.current.iso8601 } }
    assert_equal [ customers(:haq), "opening_balance" ], [ Payment.last.customer, Payment.last.against ]
  end

  test "problems are shown on the form" do
    sign_in_as users(:accountant)
    post payments_path, params: { payment: { customer_id: customers(:khan).id, against_choice: "invoice:#{@bill.id}", amount: "50000", method: "cheque", date: Date.current.iso8601 } }

    assert_response :unprocessable_content
    assert_match "still due on #{@bill.number}", response.body
    assert_match "Cheque no. / TID is needed", response.body
  end

  test "only partners reverse, and sales staff can't see payments" do
    pay = Payment.receive!(company: companies(:hassan), by: users(:accountant), customer: customers(:khan), invoice: @bill, amount: 100, method: "cash", date: Date.current)
    sign_in_as users(:accountant)
    post reverse_payment_path(pay), params: { reason: "x" }
    assert_response :forbidden

    sign_in_as users(:partner)
    post reverse_payment_path(pay), params: { reason: "Cheque bounced" }
    assert pay.reload.reversed?

    sign_in_as users(:sales)
    get payments_path
    assert_response :forbidden
  end

  test "list, receipt PDF and bill page" do
    pay = Payment.receive!(company: companies(:hassan), by: users(:accountant), customer: customers(:khan), invoice: @bill, amount: 1000, method: "jazzcash", ref: "TID 123", date: Date.current)
    sign_in_as users(:partner)

    get payments_path(tab: "jazzcash")
    assert_select "tbody tr", 1
    get payment_path(pay, format: :pdf)
    assert_equal "application/pdf", response.media_type
    get invoice_path(@bill)
    assert_select "#invoice-payments td", text: pay.number
  end
end
