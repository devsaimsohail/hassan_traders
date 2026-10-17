class Users::SessionsController < Devise::SessionsController
  skip_before_action :authenticate_user!, :require_company, :require_password_change

  layout "auth"
end
