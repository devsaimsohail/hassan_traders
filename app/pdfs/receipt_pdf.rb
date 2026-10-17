class ReceiptPdf
  def initialize(payment, user:)
    @payment = payment
    @user = user
  end

  def render
    pay = @payment
    ReportPdf.new(
      company: pay.company, user: @user, title: "Receipt #{pay.number}",
      meta: [ "Received from: #{pay.customer.name}#{", #{pay.customer.place}" if pay.customer.place.present?}",
              [ "Date: #{Fmt.date(pay.date)}", "Method: #{pay.method_label}", pay.ref.presence ].compact.join("   |   "),
              "Received by: #{pay.received_by.name}" ],
      summary: [ [ "Amount received", Fmt.rs(pay.amount) ] ],
      columns: [ { label: "Description", width: 75 }, { label: "Amount", width: 25, align: :right } ],
      rows: [ [ "Payment against #{pay.against_label}", Fmt.rs(pay.amount) ] ],
      totals: [ "Total", Fmt.rs(pay.amount) ],
      after: [ pay.reversed? ? "This receipt was reversed on #{Fmt.date(pay.reversed_at)}: #{pay.reverse_reason}" : "Thank you. Shukriya!" ],
      footer: "#{pay.company.name} - computer generated receipt, no signature needed"
    ).render
  end
end
