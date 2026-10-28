class SupplierPaymentList < ListView
  self.title = "Supplier payments"
  self.search_columns = %w[suppliers.name purchase_orders.number supplier_payments.ref supplier_payments.note]
  self.search_placeholder = "Search supplier, PO, cheque, TID or description"
  self.date_column = "supplier_payments.date"
  self.default_sort = [ :date, :desc ]
  self.pdf_landscape = true
  self.tab_group = "Method"

  tab :all, "All"
  SupplierPayment::METHODS.each { |key, label| tab key, label, ->(s) { s.where(method: key) } }

  select :supplier, "Supplier", all_label: "All suppliers", column: "suppliers.name"
  select :payer, "Paid by", all_label: "Paid by anyone", column: "payers.name"

  column :date, "Date", sort: "supplier_payments.date", format: :date, pdf_width: 9
  column :supplier_name, "Supplier", sort: "suppliers.name", nowrap: true, pdf_width: 17
  column :po_number, "PO #", sort: "purchase_orders.number", nowrap: true, pdf_width: 8
  column :method_label, "Method", sort: "supplier_payments.method", nowrap: true, pdf_width: 10
  column :ref, "Cheque / TID", optional: true, nowrap: true, pdf_width: 13
  column :note, "Description", optional: true, pdf_width: 21
  column :amount, "Amount", sort: "supplier_payments.amount", format: :rs, align: :right, pdf_width: 10
  column :payer_name, "Paid by", sort: "payers.name", optional: true, nowrap: true, pdf_width: 12

  def self.base(company)
    company.supplier_payments.joins(:supplier).left_joins(:purchase_order)
      .joins("LEFT JOIN users payers ON payers.id = supplier_payments.user_id")
      .select("supplier_payments.*, suppliers.name AS supplier_name, purchase_orders.number AS po_number, payers.name AS payer_name")
  end

  # Takes the company, not a base scope, because "Still to pay" reads purchase orders too.
  def initialize(company, params)
    @company = company
    super(self.class.base(company), params)
  end

  def totals
    payments = scope.unscope(:select)
    total = payments.sum(:amount)
    cash = payments.where(method: "cash").sum(:amount)
    [ [ "Payments", Fmt.lakh(total_count) ], [ "Total paid", Fmt.rs(total), :good ], [ "Cash", Fmt.rs(cash) ],
      [ "Bank, cheque, wallet", Fmt.rs(total - cash) ], [ "Still to pay", Fmt.rs(still_to_pay), (:bad if still_to_pay.positive?) ] ]
  end

  def pdf_totals
    pdf_columns.map { |c| { date: "Total", amount: Fmt.rs(scope.unscope(:select).sum(:amount)) }.fetch(c.key, "") }
  end

  private
    # What the business still owes on received POs: for the chosen supplier, or for all of them.
    def still_to_pay
      @still_to_pay ||= begin
        suppliers = @company.suppliers
        suppliers = suppliers.where(name: selected(selects.first)) if selected(selects.first)
        suppliers.sum(&:to_pay)
      end
    end
end
