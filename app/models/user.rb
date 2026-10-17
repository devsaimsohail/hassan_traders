class User < ApplicationRecord
  rolify strict: true

  devise :database_authenticatable, :trackable, :lockable, :timeoutable, :rememberable

  belongs_to :disabled_by, class_name: "User", optional: true

  normalizes :mobile, with: ->(m) { User.normalize_mobile(m) }
  normalizes :email, with: ->(e) { e.strip.downcase.presence }

  validates :name, presence: true
  validates :mobile, presence: true, uniqueness: true, format: { with: /\A03\d{9}\z/, message: "must be a Pakistani mobile number like 0300-1234567" }
  validates :password, presence: true, on: :create
  validates :password, length: { in: Devise.password_length }, confirmation: true, allow_nil: true

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

  def active_for_authentication?
    super && !disabled?
  end

  def inactive_message
    disabled? ? :disabled : super
  end
end
