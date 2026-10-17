class SettingsController < ApplicationController
  def show
    @company = Current.company
    authorize @company
    @people = @company.people
    @levels = Company::ROLES.keys.index_with { |role| @company.permission_levels(role) }
  end
end
