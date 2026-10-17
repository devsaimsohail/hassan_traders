class StockList < ListView
  STATUS_TONES = { "OK" => "pill-ok", "Low" => "pill-warn", "Out of stock" => "pill-bad" }.freeze

  self.title = "Stock report"
  self.search_columns = %w[items.name items.code]
  self.search_placeholder = "Search item name or code"
  self.default_sort = [ :code, :asc ]
  self.tab_group = "Type"

  tab :all, "All"
  tab :raw, "Raw material", ->(s) { s.where(category: "raw_material") }
  tab :finished, "Finished goods", ->(s) { s.where(category: "product") }

  select :status, "Status", all_label: "Status: all"

  column :code, "Code", sort: "items.code", pdf_width: 6
  column :name, "Item", sort: "items.name", nowrap: true, pdf_width: 22
  column :category, "Type", sort: "items.category", optional: true, pdf_width: 11
  column :stock, "In stock", sort: "items.stock", format: :qty, align: :right, pdf_width: 10
  column :unit, "Unit", pdf_width: 6
  column :reorder_level, "Reorder at", sort: "items.reorder_level", format: :qty, align: :right, optional: true, pdf_width: 9
  column :rate, "Avg rate", format: :rs, align: :right, pdf_only: true, pdf_width: 10
  column :value, "Value", sort: "items.value", format: :rs, align: :right, pdf_width: 13
  column :last_in, "Last received", sort: "items.last_in", format: :date, optional: true
  column :status, "Status", sort: "items.status", format: :pill, tones: STATUS_TONES, pdf_width: 9

  def value(row, column)
    column.key == :category ? row.category_label : super
  end

  def flagged?(row) = row.status != "OK"

  def totals
    [
      [ "Items", Fmt.lakh(scope.count) ],
      [ "Stock value", Fmt.rs(scope.sum(:value)) ],
      [ "Low or out", Fmt.lakh(scope.where.not(status: "OK").count), :warn ]
    ]
  end

  def pdf_totals
    pdf_columns.map { |c| c.key == :code ? "Total" : (c.key == :value ? Fmt.rs(scope.sum(:value)) : "") }
  end
end
