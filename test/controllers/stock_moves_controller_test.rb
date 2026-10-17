require "test_helper"

class StockMovesControllerTest < ActionDispatch::IntegrationTest
  setup do
    companies(:hassan).stock_moves.create!(item: items(:yarn), user: users(:store), direction: "out", reason: "production_issue", qty: 10, date: Date.current, ref: "PI-1")
  end

  test "lists this month's moves and filters by direction" do
    sign_in_as users(:partner)
    get stock_moves_path

    assert_response :success
    assert_select "tbody tr", 1

    get stock_moves_path(tab: "in")
    assert_select "tbody tr", 0
  end

  test "rows open the item when the ref has no page" do
    sign_in_as users(:partner)
    get stock_moves_path

    assert_select "tr[data-row-link-href-value='#{item_path(items(:yarn))}']"
  end

  test "the register PDF follows the filters" do
    sign_in_as users(:partner)
    get stock_moves_path(format: :pdf, tab: "out")

    assert_equal "application/pdf", response.media_type
  end
end
