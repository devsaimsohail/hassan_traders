require "test_helper"

class DashboardTest < ActiveSupport::TestCase
  setup do
    @company = companies(:hassan)
    @today = Date.new(2026, 10, 18)
    bill_on(Date.new(2026, 10, 5), 10)
    bill_on(Date.new(2026, 9, 10), 5)
    bill_on(Date.new(2026, 9, 25), 100)
  end

  def bill_on(day, qty)
    so = @company.sales_orders.create!(customer: customers(:rehman), date: day, booked_by: users(:sales), lines_attributes: [ { item_id: items(:suit).id, qty:, rate: 1000 } ])
    so.dispatch!(by: users(:store), on: day)
  end

  test "this month against the same days of last month" do
    d = Dashboard.new(@company, today: @today)
    assert_equal Date.new(2026, 9, 1)..Date.new(2026, 9, 18), d.same_days_last_month
    assert_equal [ 10_000, 5_000, 100.0 ], [ d.sales_this, d.sales_prev, d.sales_change ]
  end

  test "same days are capped at the end of a short month" do
    d = Dashboard.new(@company, today: Date.new(2026, 3, 31))
    assert_equal Date.new(2026, 2, 1)..Date.new(2026, 2, 28), d.same_days_last_month
  end

  test "money figures match the lists" do
    d = Dashboard.new(@company, today: @today)
    assert_equal Customer.with_balances(@today).sum("customers.balance"), d.receivable
    assert_equal [ 1, 5_000 ], d.overdue_bills.map(&:to_i)
    assert_equal({ "Low" => 1 }, d.stock_alerts)
  end

  test "six months of sales, received and purchases" do
    months = Dashboard.new(@company, today: @today).months
    assert_equal 6, months.size
    assert_equal [ "May", "Oct (1–18)" ], [ months.first.label(@today), months.last.label(@today) ]
    assert_equal [ 105_000, 10_000 ], months.last(2).map(&:sales)
  end
end
