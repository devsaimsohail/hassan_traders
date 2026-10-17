class PasswordsController < ApplicationController
  skip_before_action :require_password_change

  def edit
  end

  def update
    if current_user.update_with_password(password_params.merge(must_change_password: false))
      bypass_sign_in current_user
      ActivityLog.record!(action: "Edited", section: "Users", detail: "Changed own password")
      redirect_to root_path, notice: "Password changed. You are logged out on other devices."
    else
      flash.now[:alert] = current_user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_content
    end
  end

  private
    def password_params
      params.permit(:current_password, :password, :password_confirmation)
    end
end
