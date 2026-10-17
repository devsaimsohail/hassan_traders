class StockMove < ApplicationRecord
  REASONS = {
    "purchase_receive" => "Purchase receive",
    "sale_dispatch" => "Sale dispatch",
    "production_issue" => "Production issue",
    "reversal" => "Reversal"
  }.freeze
  DIRECTION_OF = { "purchase_receive" => "in", "sale_dispatch" => "out", "production_issue" => "out" }.freeze

  belongs_to :company
  belongs_to :item
  belongs_to :user, optional: true

  validates :date, presence: true
  validates :direction, inclusion: { in: %w[in out] }
  validates :reason, inclusion: { in: REASONS.keys }
  validates :qty, numericality: { greater_than: 0 }
  validate :direction_matches_reason
  validate :item_in_company

  def readonly? = persisted?
  def direction_label = direction == "in" ? "In" : "Out"
  def reason_label = REASONS[reason]

  private
    def direction_matches_reason
      expected = DIRECTION_OF[reason]
      errors.add(:direction, "doesn't fit #{reason_label}") if expected && direction != expected
    end

    def item_in_company
      errors.add(:item, "belongs to another company") if item && item.company_id != company_id
    end
end
