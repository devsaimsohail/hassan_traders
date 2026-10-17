class KhataPdf
  def initialize(khata, user:)
    @khata = khata
    @user = user
  end

  def render
    k = @khata
    c = k.customer
    ReportPdf.new(
      company: c.company, user: @user, title: "Khata statement",
      meta: [ [ "Customer: #{c.name}", c.place.presence, c.phone.presence && "Mobile: #{c.phone}" ].compact.join("   |   "),
              "Period: #{k.period_text}   |   Credit limit: #{Fmt.rs(c.credit_limit)}   |   Terms: #{c.terms_days} days" ],
      summary: [ [ "Opening (B/F)", Fmt.rs(k.opening) ], [ "Naam (bills)", Fmt.rs(k.naam) ], [ "Jama (received)", Fmt.rs(k.jama) ], [ "Closing baqaya", Fmt.rs(k.closing) ] ],
      columns: [ { label: "Date", width: 11 }, { label: "Type", width: 7 }, { label: "Ref", width: 10 }, { label: "Detail", width: 35 },
                 { label: "Naam (Dr)", width: 12, align: :right }, { label: "Jama (Cr)", width: 12, align: :right }, { label: "Baqaya", width: 13, align: :right } ],
      rows: k.entries.map { |e| [ Fmt.date(e.date), e.type, e.ref, e.detail, (Fmt.rs(e.naam) if e.naam.nonzero?), (Fmt.rs(e.jama) if e.jama.nonzero?), Fmt.rs(e.balance) ] },
      totals: [ "Total", "", "", "", Fmt.rs(k.naam), Fmt.rs(k.jama), Fmt.rs(k.closing) ],
      after: [ "Closing balance payable by #{c.name}: #{Fmt.rs(k.closing)}" ],
      footer: "#{c.company.name} - please check and confirm this khata. Any difference, call #{c.company.mobile.presence || c.company.phone}"
    ).render
  end
end
