class Item < ApplicationRecord
  CATEGORIES = { "raw_material" => "Raw material", "product" => "Finished goods" }.freeze
  CODE_PREFIX = { "raw_material" => "R", "product" => "P" }.freeze
  STATUSES = [ "OK", "Low", "Out of stock" ].freeze
  EDITABLE = %w[name category unit rate sale_price reorder_level opening_qty].freeze

  STOCK = "items.opening_qty + COALESCE(m.qty_in, 0) - COALESCE(m.qty_out, 0)".freeze
  WITH_STOCK = <<~SQL.squish.freeze
    (SELECT items.*,
      COALESCE(m.qty_in, 0) AS stock_in,
      COALESCE(m.qty_out, 0) AS stock_out,
      #{STOCK} AS stock,
      (#{STOCK}) * items.rate AS value,
      m.last_in,
      CASE WHEN #{STOCK} <= 0 THEN 'Out of stock' WHEN #{STOCK} <= items.reorder_level THEN 'Low' ELSE 'OK' END AS status
    FROM items
    LEFT JOIN (
      SELECT item_id,
        SUM(qty) FILTER (WHERE direction = 'in') AS qty_in,
        SUM(qty) FILTER (WHERE direction = 'out') AS qty_out,
        MAX(date) FILTER (WHERE direction = 'in') AS last_in
      FROM stock_moves GROUP BY item_id
    ) m ON m.item_id = items.id) AS items
  SQL

  belongs_to :company
  belongs_to :default_supplier, class_name: "Supplier", optional: true
  has_many :stock_moves, dependent: :restrict_with_exception
  has_many :purchase_order_lines, dependent: :restrict_with_exception

  scope :with_stock, -> { from(WITH_STOCK) }

  normalizes :name, :unit, with: ->(v) { v.strip.squeeze(" ") }

  validates :name, presence: true, uniqueness: { scope: :company_id, case_sensitive: false }
  validates :code, presence: true, uniqueness: { scope: :company_id }
  validates :category, inclusion: { in: CATEGORIES.keys, message: "must be chosen" }
  validates :unit, presence: true
  validate :unit_is_a_company_unit
  validates :rate, numericality: { greater_than_or_equal_to: 0 }
  validates :sale_price, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :reorder_level, :opening_qty, numericality: { greater_than_or_equal_to: 0 }
  validate :opening_qty_fixed_after_moves, on: :update

  before_validation :assign_code, on: :create
  before_validation -> { self.sale_price = nil unless product? }

  def product? = category == "product"
  def category_label = CATEGORIES[category]

  def stock
    has_attribute?(:stock) ? self[:stock] : current_stock
  end

  def current_stock
    moves = stock_moves.group(:direction).sum(:qty)
    opening_qty + moves.fetch("in", 0) - moves.fetch("out", 0)
  end

  def last_price_change
    rates = purchase_order_lines.joins(:purchase_order).merge(PurchaseOrder.where(status: "received"))
      .order("purchase_orders.received_on DESC, purchase_order_lines.id DESC").limit(2).pluck(:rate)
    return if rates.size < 2 || rates.last.zero? || rates.first == rates.last

    ((rates.first - rates.last) / rates.last * 100).round(1)
  end

  def status_tone
    { "OK" => "pill-ok", "Low" => "pill-warn", "Out of stock" => "pill-bad" }[self[:status]]
  end

  private
    def unit_is_a_company_unit
      return if unit.blank? || company.nil? || !will_save_change_to_unit?

      errors.add(:unit, "must be one of your units (Stock › Units)") unless company.units.exists?(name: unit)
    end

    def assign_code
      return if code.present? || !CODE_PREFIX.key?(category) || company.nil?

      prefix = CODE_PREFIX[category]
      last = company.items.where("code ~ ?", "^#{prefix}[0-9]+$").pluck(:code).map { |c| c[1..].to_i }.max || 0
      self.code = format("%s%02d", prefix, last + 1)
    end

    def opening_qty_fixed_after_moves
      return unless opening_qty_changed? && stock_moves.exists?

      errors.add(:opening_qty, "can't change after stock has moved")
    end
end
