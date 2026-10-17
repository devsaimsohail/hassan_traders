class ActivityLogPolicy < ApplicationPolicy
  def index?
    sees?(:activity_log)
  end
end
