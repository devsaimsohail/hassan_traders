require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "shows the login form" do
    get new_session_path
    assert_response :success
    assert_select "input[name=mobile]"
  end

  test "logs in with a mobile number and enters the only company" do
    post session_path, params: { mobile: "0300-1110003", password: "password123" }

    assert_redirected_to root_path
    assert cookies[:session_id]
    assert_equal companies(:hassan), Session.last.company
    assert_equal [ "Logged in", "Bilal Ahmed", "Accountant (Munshi)" ], [ last_log.action, last_log.user_name, last_log.role ]
  end

  test "a wrong password is refused and logged" do
    post session_path, params: { mobile: "03001110003", password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
    assert_equal 1, users(:accountant).reload.failed_login_count
    assert_equal [ "Login failed", "Wrong password" ], [ last_log.action, last_log.detail ]
  end

  test "five wrong passwords lock the login" do
    5.times { post session_path, params: { mobile: "03001110003", password: "wrong" } }
    post session_path, params: { mobile: "03001110003", password: "password123" }

    assert_redirected_to new_session_path
    assert_match "Too many wrong passwords", flash[:alert]
    assert_nil cookies[:session_id]
  end

  test "a disabled person cannot log in" do
    post session_path, params: { mobile: "03001110007", password: "password123" }

    assert_redirected_to new_session_path
    assert_match "disabled", flash[:alert]
    assert_equal "Login failed", last_log.action
  end

  test "someone in two companies picks one" do
    post session_path, params: { mobile: "03001110006", password: "password123" }
    assert_redirected_to new_company_selection_path

    follow_redirect!
    assert_select "button", text: /Madina Cloth House/

    post company_selection_path, params: { company_id: companies(:other).id }
    assert_redirected_to root_path
    assert_equal [ companies(:other), "Partner" ], [ last_log.company, last_log.role ]
  end

  test "logs out" do
    sign_in_as users(:partner)
    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end

  test "pages need a login" do
    get root_path
    assert_redirected_to new_session_path
  end
end
