require "test_helper"

class CustomerTest < ActiveSupport::TestCase
  test "gives codes in order per company" do
    assert_equal "C04", companies(:hassan).customers.create!(name: "New Lahore Fabrics").code
    assert_equal "C02", companies(:other).customers.create!(name: "Zam Zam").code
  end

  test "balance starts from the opening balance and flags over the limit" do
    haq = Customer.with_balances.find(customers(:haq).id)
    assert_equal [ 340_000, "Yes" ], [ haq.balance, haq.over_limit ]
    assert_equal "No", Customer.with_balances.find(customers(:khan).id).over_limit
  end

  test "names are unique per company and amounts can't be negative" do
    assert_not companies(:hassan).customers.new(name: "khan brothers").valid?
    assert_not companies(:hassan).customers.new(name: "X", credit_limit: -1).valid?
  end
end
