require "test_helper"

class AccessTest < ActiveSupport::TestCase
  test "levels follow the role matrix" do
    accountant = Access.new(users(:accountant), companies(:hassan))
    assert accountant.can?(:payments)
    assert accountant.sees?(:stock)
    assert_not accountant.can?(:stock)
    assert_not accountant.sees?(:settings)

    store = Access.new(users(:store), companies(:hassan))
    assert store.can?(:stock_receive)
    assert_not store.sees?(:invoices)
  end

  test "a stored permission overrides the default" do
    companies(:hassan).role_permissions.create!(role: "accountant", permission: "settings", level: "view")
    assert Access.new(users(:accountant), companies(:hassan)).sees?(:settings)
  end

  test "is invalid for a disabled user or a company without a role" do
    assert_not Access.new(users(:disabled), companies(:hassan)).valid?
    assert_not Access.new(users(:accountant), companies(:other)).valid?
    assert Access.new(users(:multi), companies(:other)).valid?
  end
end
