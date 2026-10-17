class CompanySelectionsController < ApplicationController
  skip_before_action :require_company

  layout "auth"

  def new
    @companies = Current.user.disabled? ? Company.none : Current.user.companies.order(:name)
    redirect_to new_session_path, alert: "Your login is disabled. Please ask a partner." if @companies.none?
  end

  def create
    enter_company Current.user.companies.find(params[:company_id])
  end
end
