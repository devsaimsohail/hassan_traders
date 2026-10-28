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

  test "supplier khata lists payments with filters and what is still to pay" do
    @received.pay!(by: users(:accountant), amount: 1000, method: "bank_transfer", ref: "IBFT 9", note: "Second instalment")
    khata = ->(params = {}) { SupplierPaymentList.new(companies(:hassan), ActionController::Parameters.new(params)) }

    row = khata.call(q: "instalment").rows.sole
    assert_equal [ "Usman Stitching Unit", @received.number, "Bank Transfer", "Bilal Ahmed" ], [ row.supplier_name, row.po_number, row.method_label, row.payer_name ]
    assert_equal({ "all" => 2, "cash" => 1, "bank_transfer" => 1 }, khata.call.tab_counts.select { |_, n| n.positive? })
    assert_equal [ 4000 ], khata.call(tab: "cash").rows.map(&:amount)
    assert_empty khata.call(supplier: "Kohinoor Yarn Traders").rows

    totals = khata.call.totals.to_h { |label, value, _| [ label, value ] }
    assert_equal({ "Payments" => "2", "Total paid" => "Rs 5,000", "Cash" => "Rs 4,000", "Bank, cheque, wallet" => "Rs 1,000", "Still to pay" => "Rs 5,000" }, totals)
    assert_equal "Rs 0", khata.call(supplier: "Kohinoor Yarn Traders").totals.last[1]
  end

  test "supplier list shows what is still to pay" do
    suppliers = SupplierList.new(SupplierList.base(companies(:hassan)), ActionController::Parameters.new({}))
    assert_equal({ "S01" => 0, "S02" => 6000 }, suppliers.rows.to_h { |s| [ s.code, s[:to_pay] ] })
  end
end
