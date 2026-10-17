require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "shows the role's access and the company name" do
    sign_in_as users(:store)
    get root_path

    assert_response :success
    assert_select "aside", text: /Hassan Traders/
    assert_match "Store Incharge", response.body
  end
end
