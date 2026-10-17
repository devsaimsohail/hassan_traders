class PaymentPolicy < ApplicationPolicy
  def index? = sees?(:payments)
  def show? = index?
  def create? = can?(:payments)
  def reverse? = access.present? && access.partner? && !record.reversed?
end
