require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "staff without the dashboard land on their first page" do
    sign_in_as users(:store)
    get root_path
    assert_redirected_to items_path

    follow_redirect!
    assert_select "nav a", text: "Dashboard", count: 0
  end

  test "a partner sees the figures, attention items, charts and activity" do
    so = companies(:hassan).sales_orders.create!(customer: customers(:khan), date: 70.days.ago.to_date, booked_by: users(:sales),
      lines_attributes: [ { item_id: items(:suit).id, qty: 10, rate: 3400 } ])
    so.dispatch!(by: users(:store), on: 70.days.ago.to_date)
    companies(:hassan).sales_orders.create!(customer: customers(:rehman), date: Date.current, booked_by: users(:sales),
      lines_attributes: [ { item_id: items(:suit).id, qty: 1, rate: 3400 } ])
    sign_in_as users(:partner)
    get root_path

    assert_response :success
    assert_select "#figures", text: /Customers owe you/
    assert_select "#needs-attention", text: /1 bill is past its due date/
    assert_select "#needs-attention a[href='#{invoices_path(tab: "overdue", preset: "all")}']"
    assert_select "#needs-attention", text: /1 order is not dispatched yet/
    assert_select "#needs-attention a[href='#{items_path(status: "Low")}']"
    assert_select "#who-owes a", text: "Khan Brothers"
    assert_select "#month-by-month svg rect", 18
    assert_select "#latest-activity td", text: /Bill to Khan Brothers/
  end
end
