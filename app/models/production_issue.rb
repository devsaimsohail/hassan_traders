class ProductionIssue
  include ActiveModel::Model
  include ActiveModel::Attributes

  Line = Struct.new(:item_id, :qty, keyword_init: true) do
    def blank? = item_id.blank? && qty.blank?
  end

  attribute :date, :date, default: -> { Date.current }
  attribute :note, :string
  attr_reader :company, :user, :slip_no
  attr_writer :lines

  validates :date, presence: true
  validate :lines_are_valid

  def initialize(company:, user:, **attributes)
    @company = company
    @user = user
    super(**attributes)
  end

  def lines
    @lines = Array(@lines).map { |l| l.is_a?(Line) ? l : Line.new(**l.to_h.symbolize_keys.slice(:item_id, :qty)) }
  end

  def filled_lines = lines.reject(&:blank?)

  def lines_attributes=(attributes)
    @lines = attributes.to_h.values.map { |l| Line.new(item_id: l[:item_id] || l["item_id"], qty: l[:qty] || l["qty"]) }
  end

  def raw_materials = company.items.where(category: "raw_material").order(:name)

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      items = company.items.where(id: totals.keys).order(:id).lock.index_by(&:id)
      shortages = totals.filter_map do |id, qty|
        item = items.fetch(id)
        "Only #{Fmt.qty(item.current_stock)} #{item.unit} of #{item.name} in stock" if item.current_stock < qty
      end
      if shortages.any?
        errors.add(:base, shortages.to_sentence)
        raise ActiveRecord::Rollback
      end

      @slip_no = next_slip_no
      filled_lines.each do |line|
        company.stock_moves.create!(item: items.fetch(line.item_id.to_i), user:, date:, direction: "out",
          reason: "production_issue", qty: line.qty, ref: slip_no, note:)
      end
      ActivityLog.record!(company:, user:, action: "Issued", section: "Stock", ref: slip_no,
        detail: "Issued to production: #{filled_lines.map { |l| "#{Fmt.qty(l.qty)} #{items.fetch(l.item_id.to_i).unit} #{items.fetch(l.item_id.to_i).name}" }.join(", ")}")
      true
    end || false
  end

  private
    def totals
      filled_lines.group_by { |l| l.item_id.to_i }.transform_values { |ls| ls.sum { |l| l.qty.to_d } }
    end

    def next_slip_no
      base = "PI-#{date.strftime("%y%m%d")}"
      taken = company.stock_moves.where("ref = :base OR ref LIKE :like", base:, like: "#{base}-%").distinct.count(:ref)
      taken.zero? ? base : "#{base}-#{taken + 1}"
    end

    def lines_are_valid
      errors.add(:base, "Add at least one item with a quantity") if filled_lines.empty?
      ids = raw_materials.pluck(:id)
      filled_lines.each do |line|
        errors.add(:base, "Choose a raw material item on every line") unless ids.include?(line.item_id.to_i)
        errors.add(:base, "Quantity must be more than 0") unless line.qty.to_d.positive?
      end
    end
end
