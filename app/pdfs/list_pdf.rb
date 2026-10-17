class ListPdf
  def initialize(list, company:, user:)
    @list = list
    @company = company
    @user = user
  end

  def render
    columns = @list.pdf_columns
    rows = @list.all_rows
    ReportPdf.new(
      company: @company, user: @user, title: @list.title, landscape: @list.pdf_landscape,
      meta: [ @list.filters_text.any? ? "Filters: #{@list.filters_text.join("  |  ")}" : "Filters: none, all records",
              "#{Fmt.lakh(rows.size)} records, sorted as on screen" ],
      summary: @list.totals.map { |label, value, _tone| [ label, value ] },
      columns: columns.map { |c| { label: c.label, width: c.pdf_width, align: c.right? ? :right : :left } },
      rows: rows.map { |row| columns.map { |c| format(@list.value(row, c), c) } },
      flagged: rows.each_index.select { |i| @list.flagged?(rows[i]) },
      totals: @list.pdf_totals,
      footer: "#{@company.name} - #{@list.title} - prepared from the app with the filters shown on page 1"
    ).render
  end

  def filename
    parts = [ @list.title, *@list.filters_text ].join(" ").parameterize
    "#{parts.first(110)}.pdf"
  end

  private
    def format(value, column)
      case column.format
      when :rs then Fmt.rs(value)
      when :rate then Fmt.rate(value)
      when :qty then Fmt.qty(value)
      when :date then Fmt.date(value)
      when :datetime then Fmt.datetime(value)
      else value.to_s
      end
    end
end
