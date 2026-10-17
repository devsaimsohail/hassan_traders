class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Authentication

  allow_browser versions: :modern
  stale_when_importmap_changes

  prepend_before_action :set_request_details
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
      return unless Current.session

      access = Current.company && Access.new(Current.user, Current.company)
      if access&.valid?
        Current.access = access
      else
        redirect_to new_company_selection_path
      end
    end

    def require_password_change
      redirect_to edit_password_path if Current.user&.must_change_password?
    end

    def forbidden
      render "shared/forbidden", status: :forbidden
    end
end
