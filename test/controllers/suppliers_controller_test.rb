require "test_helper"

class SuppliersControllerTest < ActionDispatch::IntegrationTest
  test "an accountant adds a supplier with an automatic code" do
    sign_in_as users(:accountant)
    post suppliers_path, params: { supplier: { name: "Pak Dyes & Chemicals", city: "Lahore" } }

    assert_redirected_to suppliers_path
    assert_equal "S03", Supplier.find_by!(name: "Pak Dyes & Chemicals").code
  end

  test "lists suppliers and opens their POs" do
    sign_in_as users(:partner)
    get suppliers_path

    assert_select "td", text: "Kohinoor Yarn Traders"
    assert_select "tr[data-row-link-href-value='#{purchase_orders_path(supplier: "Kohinoor Yarn Traders")}']"
  end

  test "store staff can view but not add suppliers" do
    sign_in_as users(:store)
    get suppliers_path
    assert_response :success

    post suppliers_path, params: { supplier: { name: "X" } }
    assert_response :forbidden
  end
end
