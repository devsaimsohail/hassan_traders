class InvoiceList < ListView
  STATUS_TONES = { "Paid" => "pill-ok", "Partial" => "pill-warn", "Overdue" => "pill-bad", "Unpaid" => nil, "Cancelled" => "pill-mute" }.freeze

  self.title = "Bills report"
  self.search_columns = %w[invoices.number customers.name sales_orders.number customers.city]
  self.search_placeholder = "Search bill number, customer or order"
  self.date_column = "invoices.date"
  self.default_sort = [ :date, :desc ]
  self.pdf_landscape = true
  self.tab_group = "Status"

  tab :all, "All"
  %w[Unpaid Partial Overdue Paid Cancelled].each { |s| tab s.downcase, s, ->(scope) { scope.where(status: s) } }

  select :customer, "Customer", all_label: "All customers", column: "customers.name"
  select :city, "City", all_label: "All cities", column: "customers.city"

  column :number, "Bill #", sort: "invoices.number", nowrap: true, pdf_width: 8
  column :date, "Date", sort: "invoices.date", format: :date, pdf_width: 9
  column :customer_name, "Customer", sort: "customers.name", nowrap: true, pdf_width: 18
  column :customer_city, "City", sort: "customers.city", optional: true, pdf_width: 9
  column :amount, "Amount", sort: "invoices.amount", format: :rs, align: :right, pdf_width: 11
  column :received, "Received", sort: "invoices.received", format: :rs, align: :right, optional: true, pdf_width: 11
  column :balance, "Baqaya", sort: "invoices.balance", format: :rs, align: :right, pdf_width: 11
  column :due_date, "Due date", sort: "invoices.due_date", format: :date, optional: true, pdf_width: 9
  column :days_overdue, "Days late", sort: "invoices.days_overdue", align: :right, pdf_only: true, pdf_width: 6
  column :status, "Status", sort: "invoices.status", format: :pill, tones: STATUS_TONES, pdf_width: 8

  def self.base(company, on: Date.current)
    company.invoices.with_status(on).joins(:customer).left_joins(:sales_order)
      .select("invoices.*, customers.name AS customer_name, customers.city AS customer_city")
  end

  def value(row, column)
    column.key == :days_overdue ? (row.days_overdue.to_i.positive? ? row.days_overdue : "") : super
  end

  def flagged?(row) = row.status == "Overdue"

  def totals
    sums = live_sums
    [ [ "Bills", Fmt.lakh(scope.unscope(:select).count) ], [ "Bill amount", Fmt.rs(sums[0]) ], [ "Received", Fmt.rs(sums[1]), :good ], [ "Baqaya", Fmt.rs(sums[2]), :bad ] ]
  end

  def pdf_totals
    sums = live_sums
    pdf_columns.map { |c| { number: "Total", amount: Fmt.rs(sums[0]), received: Fmt.rs(sums[1]), balance: Fmt.rs(sums[2]) }.fetch(c.key, "") }
  end

  private
    def live_sums
      scope.unscope(:select).where(cancelled_at: nil)
        .pick(Arel.sql("COALESCE(SUM(invoices.amount), 0), COALESCE(SUM(invoices.received), 0), COALESCE(SUM(invoices.balance), 0)"))
    end
end
