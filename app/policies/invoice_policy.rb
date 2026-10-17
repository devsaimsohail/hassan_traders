class InvoicePolicy < ApplicationPolicy
  def index? = sees?(:invoices)
  def show? = index?
  def extend_due? = partner? && !record.cancelled? && record.status_now != "Paid"
  def cancel? = partner? && !record.cancelled?

  private
    def partner? = access.present? && access.partner?
end
