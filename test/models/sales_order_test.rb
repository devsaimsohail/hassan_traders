require "test_helper"

class SalesOrderTest < ActiveSupport::TestCase
  def order(lines, customer: customers(:khan))
    companies(:hassan).sales_orders.create!(customer:, date: Date.current, booked_by: users(:sales), lines_attributes: lines)
  end

  test "numbers start at SO-3001 and only finished goods can be ordered" do
    assert_equal "SO-3001", order([ { item_id: items(:suit).id, qty: 10, rate: 3400 } ]).number
    bad = companies(:hassan).sales_orders.new(customer: customers(:khan), date: Date.current, booked_by: users(:sales), lines_attributes: [ { item_id: items(:yarn).id, qty: 1, rate: 1 } ])
    assert_not bad.valid?
  end

  test "dispatch lowers stock and makes the bill with the customer's terms" do
    so = order([ { item_id: items(:suit).id, qty: 80, rate: 3400 } ])
    invoice = so.dispatch!(by: users(:store), on: Date.new(2026, 10, 1))

    assert so.reload.dispatched?
    assert_equal 820, items(:suit).current_stock
    assert_equal [ "INV-2001", 272_000, Date.new(2026, 11, 15), so ], [ invoice.number, invoice.amount, invoice.due_date, invoice.sales_order ]
    assert_equal [ [ items(:suit), 80, 3400 ] ], invoice.lines.map { |l| [ l.item, l.qty, l.rate ] }
    assert_equal [ "Dispatched", "Created" ], ActivityLog.order(:id).last(2).map(&:action)
  end

  test "dispatch is refused when stock is short and nothing changes" do
    so = order([ { item_id: items(:suit).id, qty: 901, rate: 3400 } ])
    error = assert_raises(SalesOrder::NotAllowed) { so.dispatch!(by: users(:store)) }

    assert_equal "Only 900 suit of Lawn Suit 3-Piece in stock", error.message
    assert so.reload.pending?
    assert_equal 0, Invoice.count
  end

  test "credit warning when the order goes past the limit" do
    assert_nil order([ { item_id: items(:suit).id, qty: 10, rate: 3400 } ]).credit_warning
    big = order([ { item_id: items(:suit).id, qty: 400, rate: 3400 } ])
    assert_match "over their credit limit of Rs 15,00,000", big.credit_warning
    assert_match "already over", order([ { item_id: items(:suit).id, qty: 1, rate: 1 } ], customer: customers(:haq)).credit_warning
  end

  test "deliver and cancel only from the right state" do
    so = order([ { item_id: items(:suit).id, qty: 1, rate: 3400 } ])
    assert_raises(SalesOrder::NotAllowed) { so.deliver!(by: users(:store)) }
    so.cancel!(by: users(:partner), reason: "Cancelled by customer")
    assert so.cancelled?
    assert_raises(SalesOrder::NotAllowed) { so.dispatch!(by: users(:store)) }
  end
end
