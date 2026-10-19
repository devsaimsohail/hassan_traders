class UnitList < ListView
  ITEMS = "(SELECT COUNT(*) FROM items WHERE items.company_id = units.company_id AND items.unit = units.name)".freeze

  self.title = "Units"
  self.search_columns = %w[units.name]
  self.search_placeholder = "Search unit"
  self.default_sort = [ :name, :asc ]

  column :name, "Unit", sort: "lower(units.name)", pdf_width: 20
  column :items_count, "Items using it", sort: ITEMS, format: :qty, align: :right, pdf_width: 12

  def self.base(company)
    company.units.select("units.*, #{ITEMS} AS items_count")
  end

  def totals = [ [ "Units", Fmt.lakh(scope.unscope(:select).count) ] ]
end
