require "test_helper"

class ProductionIssueTest < ActiveSupport::TestCase
  def issue(lines, date: Date.new(2026, 10, 18))
    ProductionIssue.new(company: companies(:hassan), user: users(:store), date:, lines:)
  end

  test "takes raw material out of stock on one slip and logs it" do
    pi = issue([ { item_id: items(:yarn).id, qty: "380" }, { item_id: items(:dye).id, qty: "28.5" }, {} ])

    assert pi.save
    assert_equal "PI-261018", pi.slip_no
    assert_equal [ 380, 28.5 ], StockMove.where(ref: "PI-261018").order(:item_id).map { |m| m.qty.to_f }
    assert_equal 2020, items(:yarn).current_stock

    log = ActivityLog.order(:id).last
    assert_equal [ "Issued", "Stock", "PI-261018", "Shahid Iqbal" ], [ log.action, log.section, log.ref, log.user_name ]
    assert_equal "Issued to production: 380 kg Cotton Yarn 20s, 28.5 kg Reactive Dye", log.detail
  end

  test "a second slip on the same day gets its own number" do
    issue([ { item_id: items(:yarn).id, qty: 1 } ]).save
    second = issue([ { item_id: items(:yarn).id, qty: 1 } ])

    assert second.save
    assert_equal "PI-261018-2", second.slip_no
  end

  test "refuses more than is in stock and changes nothing" do
    pi = issue([ { item_id: items(:yarn).id, qty: 100 }, { item_id: items(:dye).id, qty: 60 }, { item_id: items(:dye).id, qty: 50 } ])

    assert_not pi.save
    assert_equal "Only 100 kg of Reactive Dye in stock", pi.errors.full_messages.to_sentence
    assert_equal 0, StockMove.count
  end

  test "only raw material can be issued and there must be a line" do
    assert_not issue([ { item_id: items(:suit).id, qty: 1 } ]).save
    assert_not issue([ {} ]).save
    assert_not issue([ { item_id: items(:other_yarn).id, qty: 1 } ]).save
  end
end
