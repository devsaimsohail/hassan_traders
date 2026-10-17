class Company < ApplicationRecord
  resourcify

  ROLES = {
    "partner" => "Partner",
    "accountant" => "Accountant (Munshi)",
    "store_incharge" => "Store Incharge",
    "sales_officer" => "Sales Officer"
  }.freeze

  BRAND_SWATCHES = {
    "#0F766E" => "Teal",
    "#01411C" => "Pakistan green",
    "#1E3A8A" => "Navy",
    "#9F1239" => "Maroon",
    "#C2410C" => "Orange",
    "#6D28D9" => "Purple",
    "#111827" => "Black"
  }.freeze
  LOGO_TYPES = %w[image/png image/jpeg image/webp].freeze
  PROFILE_FIELDS = %w[name brand_color legal_name ntn strn address city phone mobile email fiscal_year_start].freeze

  has_many :role_permissions, dependent: :delete_all
  has_many :activity_logs, dependent: :restrict_with_exception
  has_many :items, dependent: :restrict_with_exception
  has_many :stock_moves, dependent: :restrict_with_exception
  has_one_attached :logo

  normalizes :brand_color, with: ->(c) { c.strip.upcase }

  validates :name, presence: true
  validates :brand_color, format: { with: /\A#[0-9A-F]{6}\z/, message: "must be a colour like #0F766E" }
  validate :logo_is_small_image

  after_create :create_default_permissions

  def brand_ink
    r, g, b = brand_color.delete("#").scan(/../).map { |hex| linear(hex.to_i(16) / 255.0) }
    0.2126 * r + 0.7152 * g + 0.0722 * b > 0.4 ? "#111111" : "#FFFFFF"
  end

  def initials
    name.to_s.split.select { |w| w.match?(/\A[[:alpha:]]/) }.first(2).map { |w| w[0].upcase }.join
  end

  def people
    User.joins(:roles).where(roles: { resource_type: "Company", resource_id: id })
      .select("users.*, roles.name AS role").order("users.created_at")
  end

  def users_with_role(name)
    User.with_role(name, self)
  end

  def permission_levels(role)
    stored = role_permissions.where(role: role).pluck(:permission, :level).to_h
    RolePermission.defaults_for(role).merge(stored)
  end

  private
    def linear(v)
      v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055)**2.4
    end

    def logo_is_small_image
      return unless logo.attached?

      errors.add(:logo, "must be a PNG, JPG or WebP image") unless logo.blob.content_type.in?(LOGO_TYPES)
      errors.add(:logo, "must be under 1 MB") if logo.blob.byte_size > 1.megabyte
    end

    def create_default_permissions
      RolePermission.seed_defaults_for(self)
    end
end
