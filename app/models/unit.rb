class Unit < ApplicationRecord
  DEFAULTS = %w[pcs dozen gross kg gram meter gaz than cone roll suit set bag carton litre].freeze

  belongs_to :company

  normalizes :name, with: ->(v) { v.strip.squeeze(" ") }

  validates :name, presence: true, length: { maximum: 20 }, uniqueness: { scope: :company_id, case_sensitive: false }

  # Items keep the unit's name, so a rename is carried to them in the same transaction.
  after_update :rename_on_items, if: :saved_change_to_name?
  before_destroy :keep_if_in_use

  def self.seed_defaults_for(company)
    existing = company.units.pluck(:name).map(&:downcase)
    DEFAULTS.each { |name| company.units.create!(name:) unless existing.include?(name) }
  end

  # By the saved name, so a rename that failed validation still finds the right items.
  def items = company.items.where(unit: name_in_database)

  private
    def rename_on_items
      company.items.where(unit: name_before_last_save).update_all(unit: name, updated_at: Time.current)
    end

    def keep_if_in_use
      return unless items.exists?

      errors.add(:base, "#{name} is used by #{items.count} #{"item".pluralize(items.count)}, so it can't be deleted")
      throw :abort
    end
end
