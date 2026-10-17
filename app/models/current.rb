class Current < ActiveSupport::CurrentAttributes
  attribute :session, :access, :device, :ip
  delegate :user, :company, to: :session, allow_nil: true
end
