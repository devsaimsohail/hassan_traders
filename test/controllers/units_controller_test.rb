require "test_helper"

class UnitsControllerTest < ActionDispatch::IntegrationTest
  test "store staff add, rename and delete units, and each is logged" do
    sign_in_as users(:store)
    get units_path
    assert_response :success
    assert_select "td", text: "kg"
    assert_select "td", text: "cone", count: 0

    post units_path, params: { unit: { name: "than" } }
    assert_redirected_to units_path
    assert_equal "Added unit than", ActivityLog.order(:id).last.detail

    patch unit_path(units(:kg)), params: { unit: { name: "kilo" } }
    assert_equal "kilo", items(:yarn).reload.unit
    assert_equal "Renamed unit kg to kilo on 2 items", ActivityLog.order(:id).last.detail

    delete unit_path(units(:kg))
    assert_redirected_to edit_unit_path(units(:kg))
    assert units(:kg).reload

    delete unit_path(units(:gross))
    assert_redirected_to units_path
    assert_not Unit.exists?(units(:gross).id)
    assert_equal "Deleted unit gross", ActivityLog.order(:id).last.detail
  end

  test "an accountant can only view units" do
    sign_in_as users(:accountant)
    get units_path
    assert_response :success
    assert_select "a", text: /Add unit/, count: 0

    post units_path, params: { unit: { name: "than" } }
    assert_response :forbidden
  end

  test "the item form picks its unit from the list" do
    sign_in_as users(:store)
    get new_item_path
    assert_select "select[name='item[unit]'] option", text: "suit"
    assert_select "select[name='item[unit]'] option", text: "cone", count: 0

    post items_path, params: { item: { name: "Lace", category: "raw_material", unit: "yard" } }
    assert_response :unprocessable_content
  end
end
