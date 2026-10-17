class ActivityLog < ApplicationRecord
  ACTIONS = [
    "Created", "Approved", "Received", "Dispatched", "Issued", "Payment received", "Edited", "Deleted",
    "Cancelled", "Reversed", "Logged in", "Login failed", "Downloaded PDF"
  ].freeze
  SECTIONS = %w[Purchase Stock Sales Invoices Payments Customers Users Settings Reports Login].freeze
  ATTENTION = [ "Deleted", "Login failed", "Edited", "Cancelled", "Reversed" ].freeze

  belongs_to :company
  belongs_to :user, optional: true

  validates :action, inclusion: { in: ACTIONS }
  validates :section, inclusion: { in: SECTIONS }
  validates :detail, presence: true

  def self.record!(action:, section:, detail:, company: Current.company, user: Current.user, ref: nil,
    old_value: nil, new_value: nil, device: Current.device, ip: Current.ip)
    role = user && company && Company::ROLES[user.role_in(company)]
    create!(company:, user:, user_name: user&.name, role:, action:, section:, detail:, ref:, old_value:, new_value:, device:, ip:)
  end

  def readonly?
    persisted?
  end
end
