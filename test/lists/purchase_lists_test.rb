require "test_helper"

class PurchaseListsTest < ActiveSupport::TestCase
  setup do
    company = companies(:hassan)
    @draft = company.purchase_orders.create!(supplier: suppliers(:kohinoor), date: Date.current, created_by: users(:accountant), lines_attributes: [ { item_id: items(:yarn).id, qty: 10, rate: 100 } ])
    @received = company.purchase_orders.create!(supplier: suppliers(:cmt), date: Date.current, created_by: users(:partner), lines_attributes: [ { item_id: items(:suit).id, qty: 5, rate: 2000 } ])
    @received.submit!(by: users(:partner))
    @received.receive!(by: users(:store))
    @received.pay!(by: users(:partner), amount: 4000, method: "cash")
  end

  def list(params = {})
    PurchaseOrderList.new(PurchaseOrderList.base(companies(:hassan)), ActionController::Parameters.new(params))
  end

  test "tabs by supplier payment and draft" do
    assert_equal({ "all" => 2, "unpaid" => 0, "partly" => 1, "paid" => 0, "draft" => 1 }, list.tab_counts)
    assert_equal [ @draft.number ], list(tab: "draft").rows.map(&:number)
  end

  test "rows carry supplier, items, paid and balance" do
    row = list(supplier: "Usman Stitching Unit").rows.sole
    assert_equal [ "Usman Stitching Unit", "Lawn Suit 3-Piece × 5 suit", 4000, 6000 ], [ row.supplier_name, row.items_text, row[:paid], row.balance ]
    assert_equal [ row ], list(q: "lawn").rows
  end

  test "totals leave drafts out of the value" do
    totals = list.totals.to_h { |label, value, _| [ label, value ] }
    assert_equal({ "Purchase orders" => "2", "Value" => "Rs 10,000", "Paid" => "Rs 4,000", "Still to pay" => "Rs 6,000" }, totals)
  end

  test "supplier list shows what is still to pay" do
    suppliers = SupplierList.new(SupplierList.base(companies(:hassan)), ActionController::Parameters.new({}))
    assert_equal({ "S01" => 0, "S02" => 6000 }, suppliers.rows.to_h { |s| [ s.code, s[:to_pay] ] })
  end
end
