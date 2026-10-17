class ApplicationController < ActionController::Base
  include Pundit::Authorization

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :set_request_details
  before_action :authenticate_user!
  before_action :require_company
  before_action :require_password_change

  rescue_from Pundit::NotAuthorizedError, with: :forbidden

  private
    def pundit_user
      Current.access
    end

    def set_request_details
      Current.device = DeviceName.from(request.user_agent)
      Current.ip = request.remote_ip
    end

    def require_company
      Current.user = current_user
      company = current_user.companies.find_by(id: session[:company_id])
      access = company && Access.new(current_user, company)

      if access&.valid?
        Current.company = company
        Current.access = access
      else
        redirect_to new_company_selection_path
      end
    end

    def require_password_change
      redirect_to edit_password_path if current_user&.must_change_password?
    end

    def enter_company(company)
      session[:company_id] = company.id
      Current.user = current_user
      Current.company = company
      Current.access = Access.new(current_user, company)
      ActivityLog.record!(action: "Logged in", section: "Login", detail: "Logged in from #{Current.device}")
    end

    def after_sign_in_path_for(user)
      companies = user.companies.to_a
      return new_company_selection_path unless companies.one?

      enter_company(companies.first)
      stored_location_for(user) || root_path
    end

    def after_sign_out_path_for(_scope)
      new_user_session_path
    end

    def forbidden
      render "shared/forbidden", status: :forbidden
    end
end
