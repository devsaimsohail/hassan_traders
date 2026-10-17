require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  setup do
    so = companies(:hassan).sales_orders.create!(customer: customers(:khan), date: Date.current, booked_by: users(:sales),
      lines_attributes: [ { item_id: items(:suit).id, qty: 10, rate: 3400 } ])
    @bill = so.dispatch!(by: users(:store))
  end

  def receive(**attrs)
    Payment.receive!(company: companies(:hassan), by: users(:accountant), customer: customers(:khan), date: Date.current, method: "cash", **attrs)
  end

  test "a payment against a bill lowers its balance and the udhaar" do
    pay = receive(invoice: @bill, amount: 10_000)

    assert_equal [ "RV-5001", "bill" ], [ pay.number, pay.against ]
    bill = Invoice.with_status.find(@bill.id)
    assert_equal [ 10_000, 24_000, "Partial" ], [ bill.received, bill.balance, bill.status ]
    khan = Customer.with_balances.find(customers(:khan).id)
    assert_equal [ 520_000 + 34_000 - 10_000, Date.current ], [ khan.balance, khan.last_payment ]
    assert_equal "Rs 10,000 Cash from Khan Brothers against #{@bill.number}", ActivityLog.order(:id).last.detail
  end

  test "can't pay more than is due on a bill or the opening balance" do
    assert_includes receive(invoice: @bill, amount: 34_001).errors.full_messages, "Amount can't be more than Rs 34,000 still due on #{@bill.number}"
    receive(against: "opening_balance", amount: 500_000)
    assert_includes receive(against: "opening_balance", amount: 20_001).errors.full_messages, "Amount can't be more than Rs 20,000 still due on Opening balance"
  end

  test "on account has no limit and needs no bill" do
    assert receive(against: "on_account", amount: 1_000_000).persisted?
  end

  test "non-cash payments need a cheque number or TID" do
    pay = receive(invoice: @bill, amount: 100, method: "cheque")
    assert_includes pay.errors.full_messages, "Cheque no. / TID is needed for a cheque, bank transfer or wallet payment"
  end

  test "a bill from another customer is refused" do
    pay = Payment.receive!(company: companies(:hassan), by: users(:accountant), customer: customers(:rehman), invoice: @bill, amount: 1, method: "cash", date: Date.current)
    assert_includes pay.errors.full_messages, "Bill belongs to another customer"
  end

  test "reversing brings the money back on the udhaar, once" do
    pay = receive(invoice: @bill, amount: 34_000)
    assert_equal "Paid", Invoice.with_status.find(@bill.id).status

    pay.reverse!(by: users(:partner), reason: "Cheque bounced")
    assert_equal "Unpaid", Invoice.with_status.find(@bill.id).status
    assert_raises(Payment::NotAllowed) { pay.reverse!(by: users(:partner), reason: "again") }
  end

  test "the database only allows reversing" do
    pay = receive(invoice: @bill, amount: 100)
    assert_raises(ActiveRecord::StatementInvalid) { Payment.where(id: pay.id).update_all(amount: 1) }
  end

  test "the database refuses deletes" do
    pay = receive(invoice: @bill, amount: 100)
    assert_raises(ActiveRecord::StatementInvalid) { Payment.where(id: pay.id).delete_all }
  end
end
