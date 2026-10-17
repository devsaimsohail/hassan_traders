require "test_helper"

class KhataControllerTest < ActionDispatch::IntegrationTest
  test "shows the customer who owes most by default, with entries" do
    sign_in_as users(:accountant)
    get khata_path

    assert_response :success
    assert_select "#khata h2", text: "Khan Brothers"
    assert_select "#khata td", text: "Opening balance"
  end

  test "a period and the statement PDF" do
    sign_in_as users(:sales)
    get khata_path(customer_id: customers(:haq).id, preset: "month")
    assert_response :success
    assert_select "#khata h2", text: "Haq Bahu Collection"

    get khata_path(customer_id: customers(:haq).id, preset: "all", format: :pdf)
    assert_equal "application/pdf", response.media_type
    assert_equal "Downloaded khata for Haq Bahu Collection (All dates)", ActivityLog.order(:id).last.detail
  end

  test "store staff can't open the khata" do
    sign_in_as users(:store)
    get khata_path
    assert_response :forbidden
  end
end
