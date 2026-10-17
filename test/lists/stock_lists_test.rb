require "test_helper"

class StockListsTest < ActiveSupport::TestCase
  def stock(params = {})
    StockList.new(companies(:hassan).items.with_stock, ActionController::Parameters.new(params))
  end

  def moves(params = {})
    StockMoveList.new(StockMoveList.base(companies(:hassan)), ActionController::Parameters.new(params))
  end

  test "stock tabs, status filter and totals" do
    assert_equal({ "all" => 3, "raw" => 2, "finished" => 1 }, stock.tab_counts)
    assert_equal [ "R02" ], stock(status: "Low").rows.map(&:code)
    assert_equal [ "Items", "Stock value", "Low or out" ], stock.totals.map(&:first)
    assert_equal Fmt.rs(2400 * 720 + 100 * 2600 + 900 * 2350), stock.totals[1][1]
    assert stock.flagged?(stock(status: "Low").rows.first)
    assert_equal [ [ "Low", "Low" ], [ "OK", "OK" ] ], stock.options_for(stock.selects.first)
  end

  test "register filters by direction, reason and item" do
    company = companies(:hassan)
    company.stock_moves.create!(item: items(:yarn), user: users(:store), direction: "out", reason: "production_issue", qty: 10, date: Date.current, ref: "PI-1")
    company.stock_moves.create!(item: items(:suit), direction: "out", reason: "sale_dispatch", qty: 4, date: Date.current, ref: "SO-1")

    assert_equal({ "all" => 2, "in" => 0, "out" => 2 }, moves.tab_counts)
    assert_equal [ "Cotton Yarn 20s" ], moves(reason: "production_issue").rows.map(&:item_name)
    assert_equal "Shahid Iqbal", moves(item: "Cotton Yarn 20s").rows.first.by_name
    assert_includes moves(reason: "production_issue").filters_text, "Reason: Production issue"
    assert_equal [ [ "Production issue", "production_issue" ], [ "Sale dispatch", "sale_dispatch" ] ], moves.options_for(moves.selects[1])
  end
end
