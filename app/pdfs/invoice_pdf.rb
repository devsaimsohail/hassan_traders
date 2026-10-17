class InvoicePdf
  def initialize(invoice, user:)
    @invoice = invoice
    @user = user
  end

  def render
    inv = @invoice
    ReportPdf.new(
      company: inv.company, user: @user, title: "Bill #{inv.number}",
      meta: [ "Bill to: #{inv.customer.name}#{", #{inv.customer.place}" if inv.customer.place.present?}",
              [ "Bill date: #{Fmt.date(inv.date)}", "Due date: #{Fmt.date(inv.due_date)}", (inv.sales_order && "Order: #{inv.sales_order.number}") ].compact.join("   |   "),
              "Status: #{inv.status}#{" (#{inv.days_overdue} days late)" if inv.days_overdue.to_i.positive?}" ],
      summary: [ [ "Bill amount", Fmt.rs(inv.amount) ], [ "Received", Fmt.rs(inv.received) ], [ "Balance due", Fmt.rs(inv.balance) ] ],
      columns: LineColumns::COLUMNS,
      rows: inv.lines.map { |l| [ l.item.name, Fmt.qty(l.qty), l.item.unit, Fmt.rate(l.rate), Fmt.rs(l.amount) ] },
      totals: [ "Total", Fmt.qty(inv.lines.sum(&:qty)), "", "", Fmt.rs(inv.amount) ],
      after: [ inv.cancelled? ? "This bill was cancelled: #{inv.cancel_reason}" : (inv.balance.positive? ? "Balance due: #{Fmt.rs(inv.balance)} by #{Fmt.date(inv.due_date)}" : "Fully paid. Shukriya!") ],
      footer: "#{inv.company.name} - computer generated bill, no signature needed"
    ).render
  end
end
