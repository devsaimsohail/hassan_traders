class RolePermission < ApplicationRecord
  PERMISSIONS = {
    "dashboard" => "Dashboard",
    "stock" => "Stock",
    "purchase_create" => "Make PO",
    "purchase_approve" => "Approve PO",
    "stock_receive" => "Receive goods",
    "sales" => "Sales orders",
    "invoices" => "Bills",
    "payments" => "Payments",
    "khata" => "Khata and customers",
    "activity_log" => "Activity log",
    "settings" => "Settings"
  }.freeze

  LEVELS = %w[yes view no].freeze

  DEFAULTS = {
    "partner" => PERMISSIONS.keys.index_with("yes"),
    "accountant" => {
      "dashboard" => "yes", "stock" => "view", "purchase_create" => "yes", "purchase_approve" => "no",
      "stock_receive" => "no", "sales" => "view", "invoices" => "yes", "payments" => "yes",
      "khata" => "yes", "activity_log" => "view", "settings" => "no"
    },
    "store_incharge" => {
      "dashboard" => "no", "stock" => "yes", "purchase_create" => "view", "purchase_approve" => "no",
      "stock_receive" => "yes", "sales" => "view", "invoices" => "no", "payments" => "no",
      "khata" => "no", "activity_log" => "no", "settings" => "no"
    },
    "sales_officer" => {
      "dashboard" => "no", "stock" => "view", "purchase_create" => "no", "purchase_approve" => "no",
      "stock_receive" => "no", "sales" => "yes", "invoices" => "view", "payments" => "no",
      "khata" => "view", "activity_log" => "no", "settings" => "no"
    }
  }.freeze

  belongs_to :company

  validates :role, inclusion: { in: Company::ROLES.keys }
  validates :permission, inclusion: { in: PERMISSIONS.keys }, uniqueness: { scope: [ :company_id, :role ] }
  validates :level, inclusion: { in: LEVELS }

  def self.defaults_for(role)
    DEFAULTS.fetch(role.to_s, {})
  end

  def self.seed_defaults_for(company)
    now = Time.current
    rows = DEFAULTS.flat_map do |role, levels|
      levels.map { |permission, level| { company_id: company.id, role:, permission:, level:, created_at: now, updated_at: now } }
    end
    insert_all(rows, unique_by: [ :company_id, :role, :permission ])
  end
end
