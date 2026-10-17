class StockMoveList < ListView
  self.title = "Stock in-out register"
  self.search_columns = %w[items.name stock_moves.ref users.name]
  self.search_placeholder = "Search item, PO, order or slip number"
  self.date_column = "stock_moves.date"
  self.default_preset = "month"
  self.default_sort = [ :date, :desc ]
  self.tab_group = "Direction"

  tab :all, "All"
  tab :in, "In", ->(s) { s.where(direction: "in") }
  tab :out, "Out", ->(s) { s.where(direction: "out") }

  select :item, "Item", all_label: "All items", column: "items.name"
  select :reason, "Reason", all_label: "All reasons", column: "stock_moves.reason", labels: StockMove::REASONS
  select :person, "Done by", all_label: "Done by anyone", column: "users.name"

  column :date, "Date", sort: "stock_moves.date", format: :date, pdf_width: 10
  column :item_name, "Item", sort: "items.name", nowrap: true, pdf_width: 22
  column :direction_label, "In / Out", sort: "stock_moves.direction", format: :pill, tones: { "In" => "pill-ok", "Out" => "pill-info" }, pdf_width: 7
  column :reason_label, "Reason", sort: "stock_moves.reason", optional: true, pdf_width: 14
  column :qty, "Qty", sort: "stock_moves.qty", format: :qty, align: :right, pdf_width: 9
  column :unit, "Unit", pdf_width: 6
  column :ref, "Against", sort: "stock_moves.ref", pdf_width: 11
  column :by_name, "Done by", sort: "users.name", optional: true, pdf_width: 13

  def self.base(company)
    company.stock_moves.joins(:item).left_joins(:user)
      .select("stock_moves.*, items.name AS item_name, items.unit AS unit, users.name AS by_name")
  end

  def totals
    counts = scope.unscope(:select).group(:direction).count
    [
      [ "Entries", Fmt.lakh(counts.values.sum) ],
      [ "In entries", Fmt.lakh(counts.fetch("in", 0)) ],
      [ "Out entries", Fmt.lakh(counts.fetch("out", 0)) ]
    ]
  end
end
