class SupplierPolicy < ApplicationPolicy
  def index? = sees?(:purchase_create) || sees?(:purchase_approve)
  def show? = index?
  def create? = can?(:purchase_create)
  def update? = create?
end
