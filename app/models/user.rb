class User < ApplicationRecord
  rolify strict: true

  MAX_FAILED_LOGINS = 5
  LOCK_PERIOD = 15.minutes

  has_secure_password
  has_many :sessions, dependent: :destroy
  belongs_to :disabled_by, class_name: "User", optional: true

  normalizes :mobile, with: ->(m) { User.normalize_mobile(m) }
  normalizes :email, with: ->(e) { e.strip.downcase.presence }

  validates :name, presence: true
  validates :mobile, presence: true, uniqueness: true, format: { with: /\A03\d{9}\z/, message: "must be a Pakistani mobile number like 0300-1234567" }
  validates :password, length: { minimum: 8 }, allow_nil: true

  scope :enabled, -> { where(disabled_at: nil) }

  def self.normalize_mobile(value)
    digits = value.to_s.gsub(/\D/, "")
    digits = "0#{digits[2..]}" if digits.start_with?("92") && digits.length == 12
    digits
  end

  def companies
    Company.where(id: roles.where(resource_type: "Company").select(:resource_id))
  end

  def role_in(company)
    roles.find_by(resource: company)&.name
  end

  def assign_role!(name, company)
    (Company::ROLES.keys - [ name.to_s ]).each { |other| remove_role(other, company) if has_role?(other, company) }
    add_role(name, company)
  end

  def mobile_display
    mobile.to_s.sub(/\A(\d{4})(\d{7})\z/, '\1-\2')
  end

  def initials
    name.to_s.split.first(2).map { |w| w[0].upcase }.join
  end

  def disabled?
    disabled_at.present?
  end

  def locked?
    locked_until.present? && locked_until.future?
  end

  def record_failed_login!
    count = locked_until&.past? ? 1 : failed_login_count + 1
    update!(failed_login_count: count, locked_until: count >= MAX_FAILED_LOGINS ? LOCK_PERIOD.from_now : nil)
  end

  def record_login!(device)
    update!(failed_login_count: 0, locked_until: nil, last_login_at: Time.current, last_device: device)
  end
end
