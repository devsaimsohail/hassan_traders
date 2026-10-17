require "test_helper"

class CompanyTest < ActiveSupport::TestCase
  test "picks white text on dark brand colours and dark text on light ones" do
    assert_equal "#FFFFFF", Company.new(brand_color: "#0F766E").brand_ink
    assert_equal "#111111", Company.new(brand_color: "#FDE68A").brand_ink
  end

  test "stores the default permission matrix when created" do
    company = Company.create!(name: "New Co")
    assert_equal RolePermission::DEFAULTS.values.sum(&:size), company.role_permissions.count
    assert_equal "view", company.permission_levels("store_incharge")["purchase_create"]
  end

  test "rejects a brand colour that is not a hex code" do
    company = Company.new(name: "X", brand_color: "teal")
    assert_not company.valid?
  end

  test "lists people with their role" do
    roles = companies(:hassan).people.to_h { |p| [ p.name, p.role ] }
    assert_equal "partner", roles["Muhammad Hassan"]
    assert_equal "accountant", roles["Kamran Javed"]
  end
end
