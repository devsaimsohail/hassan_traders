require "test_helper"

class PurchaseOrderTest < ActiveSupport::TestCase
  def make_po(lines, supplier: suppliers(:kohinoor), by: users(:accountant))
    companies(:hassan).purchase_orders.create!(supplier:, date: Date.current, created_by: by, lines_attributes: lines)
  end

  test "numbers start at PO-1001 and the total adds up the lines" do
    po = make_po([ { item_id: items(:yarn).id, qty: 100, rate: 10.5 }, { item_id: items(:dye).id, qty: 2, rate: 2600 } ])
    assert_equal "PO-1001", po.number
    assert_equal 1050 + 5200, po.total
    assert_equal "PO-1002", make_po([ { item_id: items(:yarn).id, qty: 1, rate: 1 } ]).number
  end

  test "needs a line and a supplier from the same company" do
    po = companies(:hassan).purchase_orders.new(supplier: suppliers(:other_supplier), date: Date.current, created_by: users(:partner))
    assert_not po.valid?
    assert_includes po.errors.full_messages, "Add at least one item with a quantity"
    assert_includes po.errors.full_messages, "Supplier must be chosen"
  end

  test "an accountant's PO waits for approval, a partner's is approved straight away" do
    po = make_po([ { item_id: items(:yarn).id, qty: 1, rate: 1 } ])
    po.submit!(by: users(:accountant))
    assert po.pending_approval?

    po.approve!(by: users(:partner))
    assert_equal [ "approved", users(:partner) ], [ po.status, po.approved_by ]

    own = make_po([ { item_id: items(:yarn).id, qty: 1, rate: 1 } ], by: users(:partner))
    own.submit!(by: users(:partner))
    assert own.approved?
  end

  test "receiving raises stock and sets average cost and last purchase rate" do
    yarn = items(:yarn)
    yarn.update!(rate: 10, opening_qty: 100)
    companies(:hassan).stock_moves.create!(item: yarn, direction: "out", reason: "production_issue", qty: 50, date: Date.current)

    po = make_po([ { item_id: yarn.id, qty: 100, rate: 12 } ])
    po.submit!(by: users(:partner))
    changes = po.receive!(by: users(:store), on: Date.new(2026, 10, 18))

    yarn.reload
    assert_equal 150, yarn.current_stock
    assert_equal 11.33.to_d, yarn.rate
    assert_equal [ 12, Date.new(2026, 10, 18), suppliers(:kohinoor) ], [ yarn.last_purchase_rate, yarn.last_purchase_on, yarn.default_supplier ]
    assert_equal [ "received", users(:store) ], [ po.status, po.received_by ]
    assert_equal [ "PO-1001" ], StockMove.where(direction: "in").pluck(:ref)

    assert_equal 1, changes.size
    assert_equal [ 10, 12, 20.0 ], [ changes.first.old_rate, changes.first.new_rate, changes.first.percent ]
  end

  test "receiving with no stock left takes the PO rate as the cost" do
    dye = items(:dye)
    companies(:hassan).stock_moves.create!(item: dye, direction: "out", reason: "production_issue", qty: 100, date: Date.current)
    po = make_po([ { item_id: dye.id, qty: 10, rate: 2900 } ])
    po.submit!(by: users(:partner))
    po.receive!(by: users(:store))

    assert_equal 2900, dye.reload.rate
  end

  test "only approved POs can be received" do
    po = make_po([ { item_id: items(:yarn).id, qty: 1, rate: 1 } ])
    assert_raises(PurchaseOrder::NotAllowed) { po.receive!(by: users(:store)) }
    assert_equal 0, StockMove.count
  end

  test "paying the supplier, with checks on amount and reference" do
    po = make_po([ { item_id: items(:yarn).id, qty: 100, rate: 10 } ])
    po.submit!(by: users(:partner))
    assert_raises(PurchaseOrder::NotAllowed) { po.pay!(by: users(:partner), amount: 100, method: "cash") }
    po.receive!(by: users(:store))

    bad = po.pay!(by: users(:accountant), amount: 5000, method: "cheque")
    assert_includes bad.errors.full_messages, "Amount can't be more than Rs 1,000 still to pay"
    assert bad.errors[:ref].any?

    assert po.pay!(by: users(:accountant), amount: 400, method: "cash").persisted?
    assert_equal [ 600, "Partly paid" ], [ po.balance, po.pay_status ]
    assert_equal "Paid Rs 400 Cash to Kohinoor Yarn Traders", ActivityLog.order(:id).last.detail
    assert_equal 600, suppliers(:kohinoor).to_pay
  end

  test "cancelling needs a reason and never touches stock" do
    po = make_po([ { item_id: items(:yarn).id, qty: 1, rate: 1 } ])
    assert_raises(PurchaseOrder::NotAllowed) { po.cancel!(by: users(:partner), reason: "") }
    po.cancel!(by: users(:partner), reason: "Rate too high")

    assert po.cancelled?
    assert_raises(PurchaseOrder::NotAllowed) { po.cancel!(by: users(:partner), reason: "again") }
  end

  test "deleting a draft is logged" do
    po = make_po([ { item_id: items(:yarn).id, qty: 1, rate: 1 } ])
    po.discard!(by: users(:accountant))

    assert_not PurchaseOrder.exists?(po.id)
    assert_equal "Deleted draft PO for Kohinoor Yarn Traders (never sent)", ActivityLog.order(:id).last.detail
  end
end
