class SessionsController < ApplicationController
  WRONG_LOGIN = "Wrong mobile number or password."

  allow_unauthenticated_access only: %i[ new create ]
  skip_before_action :require_company, :require_password_change, only: :destroy
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Too many tries. Please wait a few minutes." }

  layout "auth"

  def new
  end

  def create
    user = User.find_by(mobile: User.normalize_mobile(params[:mobile]))

    if user.nil?
      redirect_to new_session_path, alert: WRONG_LOGIN
    elsif user.locked?
      log_failed_login(user, "Tried to log in while locked")
      redirect_to new_session_path, alert: locked_message(user)
    elsif !user.authenticate(params[:password])
      user.record_failed_login!
      log_failed_login(user, user.locked? ? "#{User::MAX_FAILED_LOGINS} wrong passwords — login locked for 15 minutes" : "Wrong password")
      redirect_to new_session_path, alert: user.locked? ? locked_message(user) : WRONG_LOGIN
    elsif user.disabled? || user.companies.none?
      log_failed_login(user, "Login refused — account is disabled")
      redirect_to new_session_path, alert: "Your login is disabled. Please ask a partner."
    else
      sign_in(user)
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end

  private
    def sign_in(user)
      user.record_login!(Current.device)
      start_new_session_for user
      companies = user.companies.to_a
      if companies.one?
        enter_company(companies.first)
      else
        redirect_to new_company_selection_path
      end
    end

    def log_failed_login(user, detail)
      user.companies.each do |company|
        ActivityLog.record!(company:, user:, action: "Login failed", section: "Login", detail:)
      end
    end

    def locked_message(user)
      "Too many wrong passwords. Try again after #{user.locked_until.strftime("%-l:%M %P")}."
    end
end
