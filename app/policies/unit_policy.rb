class UnitPolicy < ApplicationPolicy
  def index? = sees?(:stock)
  def create? = can?(:stock)
  def update? = can?(:stock)
  def destroy? = can?(:stock)
end
