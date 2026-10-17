class Access
  attr_reader :user, :company, :role

  def initialize(user, company)
    @user = user
    @company = company
    @role = user.role_in(company)
  end

  def valid?
    role.present? && !user.disabled?
  end

  def role_name
    Company::ROLES[role]
  end

  def partner?
    role == "partner"
  end

  def level(permission)
    @levels ||= company.permission_levels(role)
    @levels.fetch(permission.to_s, "no")
  end

  def can?(permission)
    level(permission) == "yes"
  end

  def sees?(permission)
    level(permission) != "no"
  end
end
