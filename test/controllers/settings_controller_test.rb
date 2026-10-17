require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  test "a partner sees settings with people and roles" do
    sign_in_as users(:partner)
    get settings_path

    assert_response :success
    assert_select "#people td", text: /Bilal Ahmed/
    assert_select "#roles td", text: "Store Incharge"
  end

  test "the settings menu item is hidden from staff and the page is refused" do
    sign_in_as users(:store)
    get root_path
    follow_redirect!
    assert_select "nav a", text: "Settings", count: 0

    get settings_path
    assert_response :forbidden
  end

  test "a partner changes the brand colour and it is logged with old and new values" do
    sign_in_as users(:partner)
    patch company_path, params: { company: { brand_color: "#9f1239", name: "Hassan Traders" } }

    assert_redirected_to settings_path
    assert_equal "#9F1239", companies(:hassan).reload.brand_color
    assert_equal [ "Edited", "Settings", "Changed brand colour" ], [ last_log.action, last_log.section, last_log.detail ]
    assert_equal({ "brand_color" => "#0F766E" }, last_log.old_value)
    assert_equal({ "brand_color" => "#9F1239" }, last_log.new_value)
  end

  test "the brand colour is applied to the page" do
    companies(:hassan).update!(brand_color: "#1E3A8A")
    sign_in_as users(:partner)
    get settings_path

    assert_select "html[style*='--brand: #1E3A8A']"
  end

  test "a logo that is not an image is refused" do
    sign_in_as users(:partner)
    file = Rack::Test::UploadedFile.new(StringIO.new("not an image"), "text/plain", original_filename: "logo.txt")
    patch company_path, params: { company: { logo: file } }

    assert_redirected_to settings_path
    assert_match "PNG, JPG or WebP", flash[:alert]
    assert_not companies(:hassan).reload.logo.attached?
  end

  test "an accountant cannot change company settings" do
    sign_in_as users(:accountant)
    patch company_path, params: { company: { brand_color: "#000000" } }

    assert_response :forbidden
    assert_equal "#0F766E", companies(:hassan).reload.brand_color
  end
end
