require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  test "someone with a temporary password must change it first" do
    users(:accountant).update!(must_change_password: true)
    sign_in_as users(:accountant)

    get root_path
    assert_redirected_to edit_password_path
  end

  test "a wrong current password is refused" do
    sign_in_as users(:accountant)
    patch password_path, params: { current_password: "wrong", password: "new-password-1", password_confirmation: "new-password-1" }

    assert_response :unprocessable_entity
  end

  test "changing the password clears the flag and is logged" do
    users(:accountant).update!(must_change_password: true)
    sign_in_as users(:accountant)
    patch password_path, params: { current_password: "password123", password: "new-password-1", password_confirmation: "new-password-1" }

    assert_redirected_to root_path
    user = users(:accountant).reload
    assert_not user.must_change_password?
    assert user.authenticate("new-password-1")
    assert_equal "Changed own password", last_log.detail
  end
end
