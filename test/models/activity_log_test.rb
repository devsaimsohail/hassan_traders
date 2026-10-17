require "test_helper"

class ActivityLogTest < ActiveSupport::TestCase
  setup do
    @log = ActivityLog.record!(company: companies(:hassan), user: users(:partner), action: "Edited", section: "Settings", detail: "Changed brand colour")
  end

  test "copies the person's name and role" do
    assert_equal "Muhammad Hassan", @log.user_name
    assert_equal "Partner", @log.role
  end

  test "cannot be changed or deleted through the model" do
    assert_raises(ActiveRecord::ReadOnlyRecord) { @log.update!(detail: "x") }
    assert_raises(ActiveRecord::ReadOnlyRecord) { @log.destroy }
  end

  test "cannot be changed or deleted in the database" do
    assert_raises(ActiveRecord::StatementInvalid) { ActivityLog.where(id: @log.id).update_all(detail: "x") }
  end

  test "cannot be deleted in the database" do
    assert_raises(ActiveRecord::StatementInvalid) { ActivityLog.where(id: @log.id).delete_all }
  end
end
