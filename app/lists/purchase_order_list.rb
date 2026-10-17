class PurchaseOrderList < ListView
  PAID = "COALESCE(pay.paid, 0)".freeze
  BALANCE = "CASE WHEN purchase_orders.status = 'received' THEN purchase_orders.total - #{PAID} ELSE 0 END".freeze
  PAY_STATUS = <<~SQL.squish.freeze
    CASE WHEN purchase_orders.status <> 'received' THEN 'Not due'
         WHEN #{PAID} >= purchase_orders.total THEN 'Paid'
         WHEN #{PAID} > 0 THEN 'Partly paid' ELSE 'Unpaid' END
  SQL

  self.title = "Purchase orders"
  self.search_columns = %w[purchase_orders.number suppliers.name items_summary.text]
  self.search_placeholder = "Search PO number, supplier or item"
  self.date_column = "purchase_orders.date"
  self.default_sort = [ :date, :desc ]
  self.pdf_landscape = true

  tab :all, "All"
  tab :unpaid, "Unpaid", ->(s) { s.where("#{PAY_STATUS} = 'Unpaid'") }
  tab :partly, "Partly paid", ->(s) { s.where("#{PAY_STATUS} = 'Partly paid'") }
  tab :paid, "Paid", ->(s) { s.where("#{PAY_STATUS} = 'Paid'") }
  tab :draft, "Draft", ->(s) { s.where(status: "draft") }

  select :supplier, "Supplier", all_label: "All suppliers", column: "suppliers.name"
  select :maker, "Made by", all_label: "Made by anyone", column: "makers.name"

  column :number, "PO #", sort: "purchase_orders.number", nowrap: true, pdf_width: 7
  column :date, "Date", sort: "purchase_orders.date", format: :date, pdf_width: 8
  column :supplier_name, "Supplier", sort: "suppliers.name", nowrap: true, pdf_width: 16
  column :items_text, "Items", optional: true, pdf_width: 26
  column :total, "Total", sort: "purchase_orders.total", format: :rs, align: :right, pdf_width: 10
  column :paid, "Paid", format: :rs, align: :right, pdf_only: true, pdf_width: 10
  column :balance, "To pay", sort: BALANCE, format: :rs, align: :right, pdf_width: 10
  column :approver_name, "Approved by", sort: "approvers.name", optional: true, nowrap: true, pdf_width: 12

  def self.base(company)
    company.purchase_orders
      .joins(:supplier)
      .joins("LEFT JOIN users makers ON makers.id = purchase_orders.created_by_id")
      .joins("LEFT JOIN users approvers ON approvers.id = purchase_orders.approved_by_id")
      .joins("LEFT JOIN (SELECT purchase_order_id, SUM(amount) AS paid FROM supplier_payments GROUP BY purchase_order_id) pay ON pay.purchase_order_id = purchase_orders.id")
      .joins(<<~SQL.squish)
        LEFT JOIN LATERAL (
          SELECT string_agg(items.name || ' × ' || TRIM(TRAILING '.' FROM TRIM(TRAILING '0' FROM l.qty::text)) || ' ' || items.unit, ', ' ORDER BY l.id) AS text
          FROM purchase_order_lines l JOIN items ON items.id = l.item_id WHERE l.purchase_order_id = purchase_orders.id
        ) items_summary ON true
      SQL
      .select("purchase_orders.*, suppliers.name AS supplier_name, approvers.name AS approver_name, items_summary.text AS items_text, #{PAID} AS paid, #{BALANCE} AS balance")
  end

  def value(row, column)
    column.key == :paid ? row[:paid] : super
  end

  def totals
    live = scope.unscope(:select).where.not(status: %w[draft cancelled])
    sums = scope.unscope(:select).pick(Arel.sql("COUNT(*), COALESCE(SUM(#{PAID}), 0), COALESCE(SUM(#{BALANCE}), 0)"))
    [
      [ "Purchase orders", Fmt.lakh(sums[0]) ],
      [ "Value", Fmt.rs(live.sum(:total)) ],
      [ "Paid", Fmt.rs(sums[1]) ],
      [ "Still to pay", Fmt.rs(sums[2]), :bad ]
    ]
  end

  def pdf_totals
    sums = scope.unscope(:select).pick(Arel.sql("COALESCE(SUM(purchase_orders.total), 0), COALESCE(SUM(#{PAID}), 0), COALESCE(SUM(#{BALANCE}), 0)"))
    pdf_columns.map do |c|
      { number: "Total", total: Fmt.rs(sums[0]), paid: Fmt.rs(sums[1]), balance: Fmt.rs(sums[2]) }.fetch(c.key, "")
    end
  end
end
