class KhataPolicy < ApplicationPolicy
  def show? = sees?(:khata)
end
