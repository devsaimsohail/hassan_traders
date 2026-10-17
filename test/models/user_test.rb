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

  test "locks after five failed logins and unlocks after fifteen minutes" do
    user = users(:accountant)
    4.times { user.record_failed_login! }
    assert_not user.locked?

    user.record_failed_login!
    assert user.locked?

    travel 16.minutes do
      assert_not user.locked?
      user.record_failed_login!
      assert_equal 1, user.failed_login_count
    end
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
