class PurchaseOrderPolicy < ApplicationPolicy
  def index? = sees?(:purchase_create) || sees?(:purchase_approve)
  def show? = index?
  def create? = can?(:purchase_create)
  def update? = create? && record.draft?
  def destroy? = update?
  def submit? = update?
  def copy? = create?
  def approve? = can?(:purchase_approve) && record.pending_approval?
  def receive? = can?(:stock_receive) && record.approved?
  def pay? = can?(:payments) && record.received? && record.balance.positive?
  def cancel? = can?(:purchase_approve) && PurchaseOrder::OPEN.include?(record.status)
end
