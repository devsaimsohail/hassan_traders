require "test_helper"

class ActivityLogListTest < ActiveSupport::TestCase
  setup do
    travel_to Time.zone.local(2026, 10, 18, 12)
    @company = companies(:hassan)
    log("Muhammad Hassan", "Logged in", "Login", "Logged in from Android", 1.hour.ago)
    log("Bilal Ahmed", "Payment received", "Payments", "Rs 50,000 cash from Khan Brothers", 2.days.ago, ref: "RV-5001")
    log("Shahid Iqbal", "Login failed", "Login", "Wrong password", 3.days.ago)
    log("Bilal Ahmed", "Edited", "Settings", "Changed brand colour", 40.days.ago)
    log("Other company", "Logged in", "Login", "Not ours", 1.hour.ago, company: companies(:other))
  end

  def log(name, action, section, detail, at, ref: nil, company: @company)
    ActivityLog.create!(company:, user_name: name, action:, section:, detail:, ref:, created_at: at)
  end

  def list(params = {})
    ActivityLogList.new(@company.activity_logs, ActionController::Parameters.new(params))
  end

  test "defaults to this month, newest first, for one company" do
    assert_equal [ "Logged in from Android", "Rs 50,000 cash from Khan Brothers", "Wrong password" ], list.rows.map(&:detail)
  end

  test "date presets" do
    assert_equal 4, list(preset: "all").rows.size
    assert_equal 1, list(preset: "today").rows.size
    assert_equal [ "Changed brand colour" ], list(preset: "last_month").rows.map(&:detail)
    assert_equal 2, list(preset: "custom", from: "2026-10-15", to: "2026-10-16").rows.size
  end

  test "search covers detail, ref and person" do
    assert_equal 1, list(q: "khan").rows.size
    assert_equal 1, list(q: "RV-5001").rows.size
    assert_equal 1, list(q: "shahid").rows.size
  end

  test "tabs count rows under the other filters" do
    counts = list(person: "Bilal Ahmed", preset: "all").tab_counts
    assert_equal({ "all" => 2, "attention" => 1, "money" => 1, "stock" => 0 }, counts)
    assert_equal [ "Changed brand colour" ], list(person: "Bilal Ahmed", preset: "all", tab: "attention").rows.map(&:detail)
  end

  test "sorts by a column and ignores unknown sort keys" do
    assert_equal "Bilal Ahmed", list(sort: "user_name", dir: "asc").rows.first.user_name
    assert_equal "Logged in from Android", list(sort: "drop table", dir: "asc").rows.first.detail
  end

  test "describes the filters for the PDF" do
    texts = list(preset: "month", section: "Payments", q: "khan", tab: "money").filters_text
    assert_equal [ "Date: 1 Oct 2026 to 18 Oct 2026", "Section: Payments", "Show: Money", "Search: \"khan\"" ], texts
  end

  test "totals and flags" do
    totals = list.totals.to_h { |label, value, _| [ label, value ] }
    assert_equal({ "Entries" => "3", "People" => "3", "Needs attention" => "1" }, totals)
    assert list.rows.find { |r| r.action == "Login failed" }.then { |r| list.flagged?(r) }
  end
end
