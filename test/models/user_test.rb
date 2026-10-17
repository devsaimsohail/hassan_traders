require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes mobile numbers to 03xxxxxxxxx" do
    assert_equal "03001234567", User.new(mobile: "+92 300-1234567").mobile
    assert_equal "03001234567", User.new(mobile: "0300 1234567").mobile
  end

  test "rejects numbers that are not Pakistani mobiles" do
    user = User.new(name: "X", mobile: "12345", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:mobile].first, "Pakistani mobile"
  end

  test "a disabled user cannot authenticate" do
    assert users(:accountant).active_for_authentication?
    assert_not users(:disabled).active_for_authentication?
    assert_equal :disabled, users(:disabled).inactive_message
  end

  test "assign_role! keeps one role per company" do
    user = users(:multi)
    user.assign_role!(:store_incharge, companies(:hassan))

    assert_equal "store_incharge", user.role_in(companies(:hassan))
    assert_equal "partner", user.role_in(companies(:other))
  end

  test "companies lists every company the user has a role in" do
    assert_equal [ companies(:hassan), companies(:other) ].sort, users(:multi).companies.sort
  end
end
