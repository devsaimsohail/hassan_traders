require "test_helper"

class PeopleControllerTest < ActionDispatch::IntegrationTest
  test "a partner adds a new accountant who must change their password" do
    sign_in_as users(:partner)

    assert_difference "User.count" do
      post people_path, params: { person: { name: "Usman Ghani", mobile: "0321-4567890", role: "accountant", password: "temp-pass-1" } }
    end

    person = User.find_by!(mobile: "03214567890")
    assert_redirected_to settings_path
    assert person.must_change_password?
    assert_equal "accountant", person.role_in(companies(:hassan))
    assert_equal "Added Usman Ghani as Accountant (Munshi)", last_log.detail
  end

  test "adding an existing mobile number gives that person a role here" do
    sign_in_as users(:partner)
    other = User.create!(name: "Zahid Khan", mobile: "03335550000", password: "own-password")
    other.assign_role!(:partner, companies(:other))

    assert_no_difference "User.count" do
      post people_path, params: { person: { name: "Ignored", mobile: "0333-5550000", role: "sales_officer", password: "x" } }
    end

    assert_equal "sales_officer", other.role_in(companies(:hassan))
    assert other.reload.valid_password?("own-password")
  end

  test "someone already in the company is not added twice" do
    sign_in_as users(:partner)
    post people_path, params: { person: { name: "Bilal", mobile: "03001110003", role: "partner" } }

    assert_response :unprocessable_entity
    assert_equal "accountant", users(:accountant).role_in(companies(:hassan))
  end

  test "staff cannot add people" do
    sign_in_as users(:accountant)
    post people_path, params: { person: { name: "X", mobile: "03009998888", role: "partner", password: "password123" } }

    assert_response :forbidden
  end

  test "disabling a person logs them out and blocks login" do
    sign_in_as users(:partner)
    patch disable_person_path(users(:sales))

    assert_redirected_to settings_path
    assert users(:sales).reload.disabled?
    assert_equal "Disabled login for Asif Ali", last_log.detail

    sign_in_as users(:sales)
    get root_path
    assert_redirected_to new_user_session_path
  end

  test "a partner unlocks a locked login" do
    users(:accountant).lock_access!
    sign_in_as users(:partner)
    patch unlock_person_path(users(:accountant))

    assert_not users(:accountant).reload.access_locked?
    assert_equal "Unlocked login for Bilal Ahmed", last_log.detail
  end

  test "a partner cannot disable themselves" do
    sign_in_as users(:partner)
    patch disable_person_path(users(:partner))

    assert_response :forbidden
  end

  test "a disabled person can be enabled again" do
    sign_in_as users(:partner)
    patch enable_person_path(users(:disabled))

    assert_not users(:disabled).reload.disabled?
    assert_equal "Enabled login for Tariq Mehmood", last_log.detail
  end

  test "people from another company cannot be touched" do
    outsider = User.create!(name: "Outsider", mobile: "03117778888", password: "password123")
    outsider.assign_role!(:accountant, companies(:other))
    sign_in_as users(:partner)

    patch disable_person_path(outsider)
    assert_response :not_found
  end
end
