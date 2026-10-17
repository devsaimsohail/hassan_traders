class CompanySelectionsController < ApplicationController
  skip_before_action :require_company, :require_password_change

  layout "auth"

  def new
    @companies = current_user.companies.order(:name)
    redirect_to root_path if session[:company_id] && @companies.one?
  end

  def create
    enter_company current_user.companies.find(params[:company_id])
    redirect_to root_path
  end
end
