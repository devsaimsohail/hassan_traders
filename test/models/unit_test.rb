require "test_helper"

class UnitTest < ActiveSupport::TestCase
  test "a new company gets the basic units" do
    company = Company.create!(name: "New Co")
    assert_equal Unit::DEFAULTS.sort, company.units.pluck(:name).sort

    Unit.seed_defaults_for(company)
    assert_equal Unit::DEFAULTS.size, company.units.count
  end

  test "names are unique per company, ignoring case" do
    assert_not companies(:hassan).units.new(name: "KG").valid?
    assert companies(:hassan).units.new(name: "cone").valid?
  end

  test "renaming a unit renames it on its items" do
    units(:kg).update!(name: "kilo")

    assert_equal "kilo", items(:yarn).reload.unit
    assert_equal "kg", items(:other_yarn).reload.unit
  end

  test "a unit in use can't be deleted" do
    assert_not units(:kg).destroy
    assert_match "used by", units(:kg).errors.full_messages.to_sentence
    assert units(:gross).destroy
  end

  test "an item's unit must be one of the company's units" do
    item = companies(:hassan).items.new(name: "Lace", category: "raw_material", unit: "yard")
    assert_not item.valid?
    assert_match "must be one of your units", item.errors[:unit].to_sentence

    item.unit = "meter"
    assert item.valid?
  end
end
