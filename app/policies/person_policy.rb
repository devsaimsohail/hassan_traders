class PersonPolicy < ApplicationPolicy
  def create?
    can?(:settings)
  end

  def disable?
    can?(:settings) && !record.disabled? && record != access.user
  end

  def enable?
    can?(:settings) && record.disabled?
  end
end
