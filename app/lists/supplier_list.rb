class SupplierList < ListView
  PAID = "(SELECT COALESCE(SUM(sp.amount), 0) FROM supplier_payments sp JOIN purchase_orders po ON po.id = sp.purchase_order_id WHERE po.supplier_id = suppliers.id AND po.status = 'received')".freeze
  RECEIVED = "(SELECT COALESCE(SUM(po.total), 0) FROM purchase_orders po WHERE po.supplier_id = suppliers.id AND po.status = 'received')".freeze
  TO_PAY = "(#{RECEIVED} - #{PAID})".freeze

  self.title = "Suppliers"
  self.search_columns = %w[suppliers.name suppliers.city suppliers.phone suppliers.supplies]
  self.search_placeholder = "Search supplier, city, phone or what they supply"
  self.default_sort = [ :code, :asc ]

  select :city, "City", all_label: "All cities", column: "suppliers.city"

  column :code, "Code", sort: "suppliers.code", pdf_width: 6
  column :name, "Supplier", sort: "suppliers.name", nowrap: true, pdf_width: 22
  column :city, "City", sort: "suppliers.city", pdf_width: 12
  column :phone, "Phone", nowrap: true, optional: true, pdf_width: 12
  column :supplies, "Supplies", optional: true, pdf_width: 20
  column :to_pay, "To pay", sort: TO_PAY, format: :rs, align: :right, pdf_width: 12

  def self.base(company)
    company.suppliers.select("suppliers.*, #{TO_PAY} AS to_pay")
  end

  def value(row, column)
    column.key == :to_pay ? row[:to_pay] : super
  end

  def totals
    [ [ "Suppliers", Fmt.lakh(scope.unscope(:select).count) ], [ "To pay", Fmt.rs(scope.unscope(:select).sum(Arel.sql(TO_PAY))), :bad ] ]
  end
end
