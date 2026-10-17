require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  def log_in(mobile, password)
    post user_session_path, params: { user: { mobile:, password: } }
  end

  test "shows the login form without any sign-up link" do
    get new_user_session_path

    assert_response :success
    assert_select "input[name='user[mobile]']"
    assert_select "a", text: /sign up/i, count: 0
  end

  test "there are no registration or password reset routes" do
    paths = Rails.application.routes.routes.map { |r| r.path.spec.to_s }
    assert_includes paths, "/login(.:format)"
    assert paths.none? { |p| p.match?(%r{/(sign_up|users/password|users/unlock|users/confirmation)}) }
  end

  test "logs in with a mobile number and enters the only company" do
    log_in "0300-1110003", "password123"

    assert_redirected_to root_path
    assert_equal companies(:hassan).id, session[:company_id]
    assert_equal [ "Logged in", "Bilal Ahmed", "Accountant (Munshi)" ], [ last_log.action, last_log.user_name, last_log.role ]

    user = users(:accountant).reload
    assert_equal 1, user.sign_in_count
    assert user.current_sign_in_at
    assert user.current_sign_in_ip
  end

  test "a wrong password is refused and logged" do
    log_in "03001110003", "wrong"

    assert_response :unprocessable_content
    assert_match "Wrong mobile number or password.", response.body
    assert_equal 1, users(:accountant).reload.failed_attempts
    assert_equal [ "Login failed", "Wrong password" ], [ last_log.action, last_log.detail ]
  end

  test "five wrong passwords lock the login and it is logged" do
    5.times { log_in "03001110003", "wrong" }
    assert users(:accountant).reload.access_locked?
    assert_equal "5 wrong passwords — login locked for 15 minutes", last_log.detail

    log_in "03001110003", "password123"
    assert_response :unprocessable_content
    assert_match "locked", response.body
    assert_equal "Tried to log in while locked", last_log.detail
  end

  test "the lock ends after 15 minutes" do
    5.times { log_in "03001110003", "wrong" }

    travel 16.minutes do
      log_in "03001110003", "password123"
      assert_redirected_to root_path
    end
  end

  test "a disabled person cannot log in" do
    log_in "03001110007", "password123"

    assert_redirected_to new_user_session_path
    assert_match "disabled", flash[:alert]
    assert_equal "Login refused — account is disabled", last_log.detail
  end

  test "someone in two companies picks one" do
    log_in "03001110006", "password123"
    assert_redirected_to new_company_selection_path

    follow_redirect!
    assert_select "button", text: /Madina Cloth House/

    post company_selection_path, params: { company_id: companies(:other).id }
    assert_redirected_to root_path
    assert_equal [ companies(:other), "Partner" ], [ last_log.company, last_log.role ]
  end

  test "logs out" do
    sign_in_as users(:partner)
    delete destroy_user_session_path

    assert_redirected_to new_user_session_path
    get root_path
    assert_redirected_to new_user_session_path
  end

  test "logs out after 12 hours" do
    sign_in_as users(:partner)

    travel 13.hours do
      get settings_path
      assert_redirected_to settings_path
      follow_redirect!
      assert_redirected_to new_user_session_path
    end
  end

  test "pages need a login" do
    get root_path
    assert_redirected_to new_user_session_path
  end
end
