require "test_helper"

class ItemsControllerTest < ActionDispatch::IntegrationTest
  test "store staff see stock and can add items" do
    sign_in_as users(:store)
    get items_path

    assert_response :success
    assert_select "td", text: "Cotton Yarn 20s"
    assert_select "td", text: "Other Yarn", count: 0
    assert_select "a", text: /Add item/
    assert_select "a", text: "Issue to production"
  end

  test "an accountant can only view stock" do
    sign_in_as users(:accountant)
    get items_path

    assert_response :success
    assert_select "a", text: /Add item/, count: 0
    assert_match "View only", response.body

    post items_path, params: { item: { name: "X", category: "raw_material", unit: "kg" } }
    assert_response :forbidden
  end

  test "the add and edit item forms open for people who can change stock" do
    sign_in_as users(:store)

    get new_item_path
    assert_response :success
    assert_select "input[name='item[name]']"

    get edit_item_path(items(:yarn))
    assert_response :success
    assert_select "input[name='item[rate]'][value='720']"
  end

  test "the sale price only shows for finished goods" do
    sign_in_as users(:partner)

    get new_item_path
    assert_select "input[name='item[category]'][value='raw_material'][checked]"
    assert_select "[data-item-form-target='productOnly'][hidden] input[name='item[sale_price]'][disabled]"

    get edit_item_path(items(:suit))
    assert_select "[data-item-form-target='productOnly']:not([hidden]) input[name='item[sale_price]']:not([disabled])"
  end

  test "an accountant cannot open the add or edit forms" do
    sign_in_as users(:accountant)

    get new_item_path
    assert_response :forbidden

    get edit_item_path(items(:yarn))
    assert_response :forbidden
  end

  test "a partner adds an item and it is logged" do
    sign_in_as users(:partner)
    post items_path, params: { item: { name: "Buttons", category: "raw_material", unit: "gross", rate: 450, reorder_level: 40, opening_qty: 120 } }

    item = Item.find_by!(name: "Buttons")
    assert_redirected_to item_path(item)
    assert_equal "R03", item.code
    assert_equal [ "Created", "Added item Buttons (R03)" ], [ ActivityLog.last.action, ActivityLog.last.detail ]
  end

  test "changing the rate is logged with old and new values" do
    sign_in_as users(:partner)
    patch item_path(items(:yarn)), params: { item: { rate: 735 } }

    log = ActivityLog.order(:id).last
    assert_equal "Changed average cost for Cotton Yarn 20s", log.detail
    assert_equal [ 720, 735 ], [ log.old_value["rate"].to_d, log.new_value["rate"].to_d ]
  end

  test "the item page shows stock and its movements" do
    companies(:hassan).stock_moves.create!(item: items(:yarn), user: users(:store), direction: "out", reason: "production_issue", qty: 400, date: Date.current, ref: "PI-1")
    sign_in_as users(:sales)
    get item_path(items(:yarn))

    assert_response :success
    assert_match "2,000 kg", response.body
    assert_select "#item-moves td", text: "PI-1"
  end

  test "the stock card and stock report PDFs download and are logged" do
    sign_in_as users(:partner)

    get item_path(items(:yarn), format: :pdf)
    assert_equal "application/pdf", response.media_type
    assert_equal "Downloaded stock card for Cotton Yarn 20s", ActivityLog.order(:id).last.detail

    get items_path(format: :pdf, tab: "raw")
    assert_equal "application/pdf", response.media_type
    assert_match "stock-report-type-raw-material.pdf", response.headers["Content-Disposition"]
  end

  test "another company's item is not found" do
    sign_in_as users(:partner)
    get item_path(items(:other_yarn))

    assert_response :not_found
  end

  test "an activity log entry about an item links to it" do
    ActivityLog.create!(company: companies(:hassan), user_name: "Bilal", action: "Edited", section: "Stock", ref: "R01", detail: "Changed rate")
    sign_in_as users(:partner)
    get activity_logs_path

    assert_select "a[href='#{item_path(items(:yarn))}']"
  end
end
