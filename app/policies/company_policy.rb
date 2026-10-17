class CompanyPolicy < ApplicationPolicy
  def show?
    sees?(:settings)
  end

  def update?
    can?(:settings)
  end
end
