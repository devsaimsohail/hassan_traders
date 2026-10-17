class ProductionIssuePolicy < ApplicationPolicy
  def create? = can?(:stock)
end
