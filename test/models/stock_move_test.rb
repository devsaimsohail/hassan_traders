require "test_helper"

class StockMoveTest < ActiveSupport::TestCase
  setup do
    @move = companies(:hassan).stock_moves.create!(item: items(:yarn), direction: "out", reason: "production_issue", qty: 5, date: Date.current)
  end

  test "cannot be changed or deleted" do
    assert_raises(ActiveRecord::ReadOnlyRecord) { @move.update!(qty: 1) }
    assert_raises(ActiveRecord::StatementInvalid) { StockMove.where(id: @move.id).update_all(qty: 1) }
  end

  test "cannot be deleted in the database" do
    assert_raises(ActiveRecord::StatementInvalid) { StockMove.where(id: @move.id).delete_all }
  end

  test "the direction must fit the reason" do
    move = companies(:hassan).stock_moves.new(item: items(:yarn), direction: "in", reason: "production_issue", qty: 5, date: Date.current)
    assert_not move.valid?
  end

  test "the item must belong to the same company" do
    move = companies(:hassan).stock_moves.new(item: items(:other_yarn), direction: "out", reason: "production_issue", qty: 5, date: Date.current)
    assert_not move.valid?
  end
end
