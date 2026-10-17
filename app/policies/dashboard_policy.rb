class DashboardPolicy < ApplicationPolicy
  def show?
    sees?(:dashboard)
  end
end
