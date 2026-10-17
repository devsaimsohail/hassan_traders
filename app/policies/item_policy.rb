class ItemPolicy < ApplicationPolicy
  def index? = sees?(:stock)
  def show? = sees?(:stock)
  def create? = can?(:stock)
  def update? = can?(:stock)
end
