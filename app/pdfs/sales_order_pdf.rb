class SalesOrderPdf
  def initialize(order, user:)
    @order = order
    @user = user
  end

  def render
    ReportPdf.new(
      company: @order.company, user: @user, title: "Sales order #{@order.number}",
      meta: [ "Customer: #{@order.customer.name}#{", #{@order.customer.place}" if @order.customer.place.present?}",
              [ "Order date: #{Fmt.date(@order.date)}", "Booked by: #{@order.booked_by.name}", "Status: #{@order.status_label}",
                (@order.invoice && "Bill: #{@order.invoice.number}") ].compact.join("   |   ") ],
      summary: [ [ "Order amount", Fmt.rs(@order.amount) ] ],
      columns: LineColumns::COLUMNS,
      rows: @order.lines.map { |l| [ l.item.name, Fmt.qty(l.qty), l.item.unit, Fmt.rate(l.rate), Fmt.rs(l.amount) ] },
      totals: [ "Total", "", "", "", Fmt.rs(@order.amount) ],
      footer: "#{@order.company.name} - computer generated sales order"
    ).render
  end
end
