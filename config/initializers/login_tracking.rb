Rails.application.config.to_prepare do
  Warden::Manager.after_authentication do |user, auth, _opts|
    user.update_column(:last_device, DeviceName.from(auth.request.user_agent))
  end

  Warden::Manager.before_failure do |env, opts|
    request = ActionDispatch::Request.new(env)
    next unless request.post? && opts[:attempted_path] == "/login"

    mobile = request.params.dig("user", "mobile")
    user = mobile.present? && User.find_by(mobile: User.normalize_mobile(mobile))
    next unless user

    detail =
      if opts[:message] == :disabled then "Login refused — account is disabled"
      elsif user.failed_attempts == Devise.maximum_attempts && user.access_locked? then "#{Devise.maximum_attempts} wrong passwords — login locked for 15 minutes"
      elsif user.access_locked? then "Tried to log in while locked"
      else "Wrong password"
      end

    user.companies.each do |company|
      ActivityLog.record!(company:, user:, action: "Login failed", section: "Login", detail:,
        device: DeviceName.from(request.user_agent), ip: request.remote_ip)
    end
  end
end
