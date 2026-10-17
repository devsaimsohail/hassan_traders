require "test_helper"

class ItemTest < ActiveSupport::TestCase
  test "gives codes in order per type and company" do
    raw = companies(:hassan).items.create!(name: "Buttons", category: "raw_material", unit: "gross")
    product = companies(:hassan).items.create!(name: "Kurta", category: "product", unit: "pcs", sale_price: 1650)
    other = companies(:other).items.create!(name: "Thread", category: "raw_material", unit: "cone")

    assert_equal [ "R03", "P02", "R02" ], [ raw.code, product.code, other.code ]
  end

  test "stock, value and status come from opening stock and moves" do
    move(items(:yarn), "out", "production_issue", 1700)
    yarn = Item.with_stock.find(items(:yarn).id)

    assert_equal 700, yarn.stock
    assert_equal 700 * 720, yarn.value
    assert_equal "Low", yarn.status
    assert_equal 1700, yarn.stock_out
    assert_equal "Low", Item.with_stock.find(items(:dye).id).status
    assert_equal "OK", Item.with_stock.find(items(:suit).id).status
  end

  test "an item with no stock is out of stock" do
    move(items(:dye), "out", "production_issue", 100)
    assert_equal "Out of stock", Item.with_stock.find(items(:dye).id).status
  end

  test "opening stock is locked once stock has moved" do
    move(items(:yarn), "out", "production_issue", 10)
    item = items(:yarn)
    item.opening_qty = 5000

    assert_not item.valid?
    assert_includes item.errors[:opening_qty], "can't change after stock has moved"
  end

  test "raw material has no sale price" do
    item = companies(:hassan).items.create!(name: "Dye 2", category: "raw_material", unit: "kg", sale_price: 999)
    assert_nil item.sale_price
  end

  private
    def move(item, direction, reason, qty)
      item.company.stock_moves.create!(item:, direction:, reason:, qty:, date: Date.current)
    end
end
