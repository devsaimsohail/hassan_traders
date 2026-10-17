class PasswordsController < ApplicationController
  skip_before_action :require_password_change

  def edit
  end

  def update
    user = Current.user

    if !user.authenticate(params[:current_password])
      flash.now[:alert] = "Your current password is not correct."
      render :edit, status: :unprocessable_entity
    elsif user.update(password: params[:password], password_confirmation: params[:password_confirmation], must_change_password: false)
      user.sessions.where.not(id: Current.session.id).destroy_all
      ActivityLog.record!(action: "Edited", section: "Users", detail: "Changed own password")
      redirect_to root_path, notice: "Password changed."
    else
      flash.now[:alert] = user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end
end
