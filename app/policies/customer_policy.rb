class CustomerPolicy < ApplicationPolicy
  def index? = sees?(:khata)
  def show? = index?
  def create? = can?(:khata)
  def update? = create?
  def change_credit_limit? = access.present? && access.partner?
end
