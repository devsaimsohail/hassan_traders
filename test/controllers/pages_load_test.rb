require "test_helper"

class PagesLoadTest < ActionDispatch::IntegrationTest
  test "every page opens for a partner" do
    sign_in_as users(:partner)
    paths = [
      root_path, settings_path, new_person_path, edit_password_path, activity_logs_path,
      items_path, new_item_path, item_path(items(:yarn)), edit_item_path(items(:yarn)),
      stock_moves_path, new_production_issue_path
    ]

    paths.each do |path|
      get path
      assert_response :success, "#{path} did not open"
    end
  end
end
