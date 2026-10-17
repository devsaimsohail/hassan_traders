class CustomerList < ListView
  self.title = "Customer balances"
  self.search_columns = %w[customers.name customers.city customers.phone customers.area customers.code]
  self.search_placeholder = "Search customer, city, area or mobile"
  self.default_sort = [ :balance, :desc ]
  self.pdf_landscape = true

  tab :all, "All"
  tab :udhaar, "Has udhaar", ->(s) { s.where("customers.balance > 0") }
  tab :overdue, "Overdue", ->(s) { s.where("customers.overdue > 0") }
  tab :over_limit, "Over credit limit", ->(s) { s.where(over_limit: "Yes") }

  select :city, "City", all_label: "All cities", column: "customers.city"

  column :name, "Customer", sort: "customers.name", nowrap: true, pdf_width: 18
  column :city, "City", sort: "customers.city", pdf_width: 9
  column :phone, "Mobile", nowrap: true, optional: true, pdf_width: 10
  column :credit_limit, "Credit limit", sort: "customers.credit_limit", format: :rs, align: :right, optional: true, pdf_width: 10
  column :billed, "Bills", format: :rs, align: :right, pdf_only: true, pdf_width: 11
  column :received, "Received", format: :rs, align: :right, pdf_only: true, pdf_width: 11
  column :balance, "Udhaar", sort: "customers.balance", format: :rs, align: :right, pdf_width: 11
  column :overdue, "Past due", sort: "customers.overdue", format: :rs, align: :right, pdf_width: 10
  column :last_payment, "Last payment", sort: "customers.last_payment", format: :date, optional: true, pdf_width: 9
  column :over_limit, "Over limit", sort: "customers.over_limit", format: :pill, tones: { "Yes" => "pill-bad", "No" => "pill-mute" }

  def flagged?(row) = row.over_limit == "Yes"

  def totals
    sums = scope.pick(Arel.sql("COUNT(*), COALESCE(SUM(customers.balance), 0), COALESCE(SUM(customers.overdue), 0), COUNT(*) FILTER (WHERE customers.over_limit = 'Yes')"))
    [
      [ "Customers", Fmt.lakh(sums[0]) ],
      [ "Total udhaar", Fmt.rs(sums[1]) ],
      [ "Past due", Fmt.rs(sums[2]), :bad ],
      [ "Over limit", Fmt.lakh(sums[3]), :warn ]
    ]
  end

  def pdf_totals
    sums = scope.pick(Arel.sql("COALESCE(SUM(customers.billed), 0), COALESCE(SUM(customers.received), 0), COALESCE(SUM(customers.balance), 0), COALESCE(SUM(customers.overdue), 0)"))
    values = { name: "Total", billed: Fmt.rs(sums[0]), received: Fmt.rs(sums[1]), balance: Fmt.rs(sums[2]), overdue: Fmt.rs(sums[3]) }
    pdf_columns.map { |c| values.fetch(c.key, "") }
  end
end
