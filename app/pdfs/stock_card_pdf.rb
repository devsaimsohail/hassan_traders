class StockCardPdf
  def initialize(item, moves_oldest_first, company:, user:)
    @item = item
    @moves = moves_oldest_first
    @company = company
    @user = user
  end

  def render
    balance = @item.opening_qty
    rows = @moves.map do |move|
      balance += move.direction == "in" ? move.qty : -move.qty
      [ Fmt.date(move.date), move.direction_label, move.reason_label, move.ref.to_s, Fmt.qty(move.qty), Fmt.qty(balance) ]
    end

    ReportPdf.new(
      company: @company, user: @user, title: "Stock card - #{@item.name}",
      meta: [ "Item: #{@item.name} (#{@item.code})   |   Unit: #{@item.unit}   |   Reorder at: #{Fmt.qty(@item.reorder_level)}" ],
      summary: [ [ "Opening", Fmt.qty(@item.opening_qty) ], [ "Received", Fmt.qty(@item.stock_in) ], [ "Sold or used", Fmt.qty(@item.stock_out) ], [ "In stock now", Fmt.qty(@item.stock) ] ],
      columns: [ { label: "Date", width: 14 }, { label: "In/Out", width: 9 }, { label: "Reason", width: 22 }, { label: "Against", width: 16 },
                 { label: "Qty", width: 12, align: :right }, { label: "Balance", width: 14, align: :right } ],
      rows:, footer: "#{@company.name} - stock card from the in / out register"
    ).render
  end
end
