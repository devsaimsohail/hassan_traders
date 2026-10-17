class PaymentList < ListView
  LIVE = "payments.reversed_at IS NULL".freeze

  self.title = "Payments received"
  self.search_columns = %w[payments.number customers.name payments.ref invoices.number]
  self.search_placeholder = "Search receipt, customer, cheque, TID or bill"
  self.date_column = "payments.date"
  self.default_preset = "month"
  self.default_sort = [ :date, :desc ]
  self.pdf_landscape = true
  self.tab_group = "Method"

  tab :all, "All"
  Payment::METHODS.each { |key, label| tab key, label, ->(s) { s.where(method: key) } }

  select :customer, "Customer", all_label: "All customers", column: "customers.name"
  select :receiver, "Received by", all_label: "Received by anyone", column: "receivers.name"

  column :number, "Receipt #", sort: "payments.number", nowrap: true, pdf_width: 8
  column :date, "Date", sort: "payments.date", format: :date, pdf_width: 9
  column :customer_name, "Customer", sort: "customers.name", nowrap: true, pdf_width: 18
  column :against_text, "Against", optional: true, nowrap: true, pdf_width: 11
  column :method_label, "Method", sort: "payments.method", nowrap: true, pdf_width: 10
  column :ref, "Cheque / TID", optional: true, nowrap: true, pdf_width: 18
  column :amount, "Amount", sort: "payments.amount", format: :rs, align: :right, pdf_width: 11
  column :receiver_name, "Received by", sort: "receivers.name", optional: true, nowrap: true, pdf_width: 12
  column :state, "", format: :pill, tones: { "Reversed" => "pill-bad" }

  def self.base(company)
    company.payments.joins(:customer).left_joins(:invoice)
      .joins("LEFT JOIN users receivers ON receivers.id = payments.received_by_id")
      .select("payments.*, customers.name AS customer_name, receivers.name AS receiver_name, invoices.number AS invoice_number")
  end

  def value(row, column)
    case column.key
    when :against_text then row[:invoice_number] || Payment::AGAINST[row.against]
    when :state then row.reversed? ? "Reversed" : nil
    else super
    end
  end

  def flagged?(row) = row.reversed?

  def totals
    live = scope.unscope(:select).where(reversed_at: nil)
    cash = live.where(method: "cash").sum(:amount)
    total = live.sum(:amount)
    [ [ "Receipts", Fmt.lakh(live.count) ], [ "Total received", Fmt.rs(total), :good ], [ "Cash", Fmt.rs(cash) ], [ "Bank, cheque, wallet", Fmt.rs(total - cash) ] ]
  end

  def pdf_totals
    pdf_columns.map { |c| { number: "Total", amount: Fmt.rs(scope.unscope(:select).where(reversed_at: nil).sum(:amount)) }.fetch(c.key, "") }
  end
end
