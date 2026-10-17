class PurchaseOrderPdf
  def initialize(purchase_order, user:)
    @po = purchase_order
    @user = user
  end

  def render
    ReportPdf.new(
      company: @po.company, user: @user, title: "Purchase order #{@po.number}",
      meta: [ "Supplier: #{@po.supplier.name}#{", #{@po.supplier.city}" if @po.supplier.city.present?}",
              [ "PO date: #{Fmt.date(@po.date)}", "Made by: #{@po.created_by.name}", (@po.approved_by && "Approved by: #{@po.approved_by.name}") ].compact.join("   |   "),
              (@po.note.present? ? "Note: #{@po.note}" : nil) ].compact,
      summary: [ [ "PO total", Fmt.rs(@po.total) ], [ "Paid", Fmt.rs(@po.paid) ], [ "To pay", Fmt.rs(@po.balance) ] ],
      columns: [ { label: "Item", width: 42 }, { label: "Qty", width: 12, align: :right }, { label: "Unit", width: 10 },
                 { label: "Rate", width: 16, align: :right }, { label: "Amount", width: 20, align: :right } ],
      rows: @po.lines.map { |l| [ l.item.name, Fmt.qty(l.qty), l.item.unit, Fmt.rate(l.rate), Fmt.rs(l.amount) ] },
      totals: [ "Total", "", "", "", Fmt.rs(@po.total) ],
      after: [ @po.received_on ? "Goods received on #{Fmt.date(@po.received_on)}" : "Please deliver to our godown and write this PO number on your bill." ],
      footer: "#{@po.company.name} - computer generated purchase order"
    ).render
  end
end
