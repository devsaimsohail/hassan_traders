require "test_helper"

class InvoiceTest < ActiveSupport::TestCase
  setup do
    so = companies(:hassan).sales_orders.create!(customer: customers(:rehman), date: Date.new(2026, 9, 1), booked_by: users(:sales),
      lines_attributes: [ { item_id: items(:suit).id, qty: 10, rate: 3400 } ])
    @invoice = so.dispatch!(by: users(:store), on: Date.new(2026, 9, 1))
  end

  def status_on(day) = Invoice.with_status(day).find(@invoice.id)

  test "unpaid before the due date, overdue after it" do
    assert_equal Date.new(2026, 10, 1), @invoice.due_date
    assert_equal [ "Unpaid", 0 ], status_on(Date.new(2026, 10, 1)).then { |i| [ i.status, i.days_overdue ] }
    assert_equal [ "Overdue", 17, 34_000 ], status_on(Date.new(2026, 10, 18)).then { |i| [ i.status, i.days_overdue, i.balance ] }
  end

  test "bills raise the customer's udhaar and overdue" do
    rehman = Customer.with_balances(Date.new(2026, 10, 18)).find(customers(:rehman).id)
    assert_equal [ 34_000, 34_000, 34_000 ], [ rehman.billed, rehman.balance, rehman.overdue ]
  end

  test "extending the due date is logged with old and new dates" do
    @invoice.extend_due!(by: users(:partner), to: Date.new(2026, 10, 31))
    assert_equal "Unpaid", status_on(Date.new(2026, 10, 18)).status
    assert_equal "Due date moved from 1 Oct 2026 to 31 Oct 2026 (30 days)", ActivityLog.order(:id).last.detail
    assert_raises(Invoice::NotAllowed) { @invoice.extend_due!(by: users(:partner), to: Date.new(2026, 10, 1)) }
  end

  test "a cancelled bill drops out of the udhaar" do
    @invoice.cancel!(by: users(:partner), reason: "Wrong rate")
    assert_equal "Cancelled", status_on(Date.new(2026, 10, 18)).status
    assert_equal 0, Customer.with_balances.find(customers(:rehman).id).balance
    assert_raises(Invoice::NotAllowed) { @invoice.cancel!(by: users(:partner), reason: "again") }
  end
end
