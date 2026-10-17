require "test_helper"

class ProductionIssuesControllerTest < ActionDispatch::IntegrationTest
  test "store staff issue raw material to production" do
    sign_in_as users(:store)
    get new_production_issue_path
    assert_response :success

    post production_issues_path, params: { production_issue: { date: "2026-10-18", lines_attributes: { "0" => { item_id: items(:yarn).id, qty: "380" }, "1" => { item_id: "", qty: "" } } } }

    assert_redirected_to stock_moves_path(q: "PI-261018", preset: "all")
    assert_equal 2020, items(:yarn).current_stock
  end

  test "asking for more than is in stock shows why" do
    sign_in_as users(:store)
    post production_issues_path, params: { production_issue: { date: "2026-10-18", lines_attributes: { "0" => { item_id: items(:dye).id, qty: "500" } } } }

    assert_response :unprocessable_content
    assert_match "Only 100 kg of Reactive Dye in stock", response.body
  end

  test "an accountant cannot issue stock" do
    sign_in_as users(:accountant)
    get new_production_issue_path

    assert_response :forbidden
  end
end
