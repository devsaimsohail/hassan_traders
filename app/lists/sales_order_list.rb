class SalesOrderList < ListView
  STATUS_TONES = { "Pending" => "pill-warn", "Dispatched" => "pill-info", "Delivered" => "pill-ok", "Cancelled" => "pill-mute" }.freeze

  self.title = "Sales orders"
  self.search_columns = %w[sales_orders.number customers.name items_summary.text invoices.number]
  self.search_placeholder = "Search order, customer, item or bill number"
  self.date_column = "sales_orders.date"
  self.default_sort = [ :date, :desc ]
  self.pdf_landscape = true
  self.tab_group = "Status"

  tab :all, "All"
  SalesOrder::STATUSES.each { |s| tab s, s.capitalize, ->(scope) { scope.where(status: s) } }

  select :customer, "Customer", all_label: "All customers", column: "customers.name"
  select :city, "City", all_label: "All cities", column: "customers.city"
  select :booker, "Booked by", all_label: "Booked by anyone", column: "bookers.name"

  column :number, "Order #", sort: "sales_orders.number", nowrap: true, pdf_width: 7
  column :date, "Date", sort: "sales_orders.date", format: :date, pdf_width: 8
  column :customer_name, "Customer", sort: "customers.name", nowrap: true, pdf_width: 16
  column :customer_city, "City", sort: "customers.city", optional: true, pdf_width: 9
  column :items_text, "Items", optional: true, pdf_width: 28
  column :amount, "Amount", sort: "sales_orders.amount", format: :rs, align: :right, pdf_width: 10
  column :status_label, "Status", sort: "sales_orders.status", format: :pill, tones: STATUS_TONES, pdf_width: 8
  column :invoice_number, "Bill #", sort: "invoices.number", optional: true, nowrap: true, pdf_width: 8

  def self.base(company)
    company.sales_orders.joins(:customer)
      .joins("LEFT JOIN users bookers ON bookers.id = sales_orders.booked_by_id")
      .joins("LEFT JOIN invoices ON invoices.sales_order_id = sales_orders.id")
      .joins(<<~SQL.squish)
        LEFT JOIN LATERAL (
          SELECT string_agg(items.name || ' × ' || TRIM(TRAILING '.' FROM TRIM(TRAILING '0' FROM l.qty::text)), ', ' ORDER BY l.id) AS text
          FROM sales_order_lines l JOIN items ON items.id = l.item_id WHERE l.sales_order_id = sales_orders.id
        ) items_summary ON true
      SQL
      .select("sales_orders.*, customers.name AS customer_name, customers.city AS customer_city, items_summary.text AS items_text, invoices.number AS invoice_number")
  end

  def totals
    base = scope.unscope(:select)
    [
      [ "Orders", Fmt.lakh(base.count) ],
      [ "Order value", Fmt.rs(base.where.not(status: "cancelled").sum(:amount)) ],
      [ "Not yet dispatched", Fmt.lakh(base.where(status: "pending").count), :warn ]
    ]
  end

  def pdf_totals
    pdf_columns.map { |c| { number: "Total", amount: Fmt.rs(scope.unscope(:select).where.not(status: "cancelled").sum(:amount)) }.fetch(c.key, "") }
  end
end
