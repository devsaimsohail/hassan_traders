class SalesOrderPolicy < ApplicationPolicy
  def index? = sees?(:sales)
  def show? = index?
  def create? = can?(:sales)
  def dispatch? = can?(:stock_receive) && record.pending?
  def deliver? = (can?(:stock_receive) || can?(:sales)) && record.dispatched?
  def cancel? = access.present? && access.partner? && record.pending?
end
