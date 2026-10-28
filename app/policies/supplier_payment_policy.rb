class SupplierPaymentPolicy < ApplicationPolicy
  def index? = sees?(:purchase_create) || sees?(:purchase_approve)
end
