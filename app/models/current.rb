class Current < ActiveSupport::CurrentAttributes
  attribute :user, :company, :access, :device, :ip
end
