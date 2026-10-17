class ReportPdf
  INK = "101828"
  MUTED = "667085"
  LINE = "D0D5DD"
  FLAG = "B42318"
  LOGO_TYPES = %w[image/png image/jpeg].freeze

  def initialize(company:, user:, title:, columns:, rows:, meta: [], summary: [], totals: nil, flagged: [], after: [], landscape: false, footer: nil)
    @company = company
    @user = user
    @title = title
    @columns = columns
    @rows = rows
    @meta = meta
    @summary = summary
    @totals = totals
    @flagged = flagged
    @after = after
    @footer = footer || "#{company.name} - #{title}"
    @pdf = Prawn::Document.new(page_size: "A4", page_layout: landscape ? :landscape : :portrait,
      margin: [ 42, 36, 46, 36 ], info: { Title: clean(title), Creator: "Hassan Traders app" })
  end

  def render
    @pdf.font("Helvetica")
    @pdf.font_size(8.5)
    brand_strip
    header
    meta_lines
    summary_boxes
    table
    after_lines
    footer
    @pdf.render
  end

  private
    def clean(value) = PdfText.clean(value)
    def brand = @company.brand_color.delete("#")

    def brand_strip
      @pdf.repeat(:all) do
        @pdf.canvas do
          @pdf.fill_color brand
          @pdf.fill_rectangle [ 0, @pdf.bounds.top ], @pdf.bounds.width, 6
          @pdf.fill_color INK
        end
      end
    end

    def header
      top = @pdf.cursor
      left = 0
      if (logo = logo_io)
        @pdf.image logo, at: [ 0, top ], fit: [ 40, 40 ]
        left = 48
      end
      @pdf.bounding_box([ left, top ], width: @pdf.bounds.width * 0.6 - left) do
        @pdf.text clean(@company.name), size: 15, style: :bold, color: INK
        @pdf.text clean(company_line), size: 7.5, color: MUTED
      end
      @pdf.bounding_box([ @pdf.bounds.width * 0.55, top ], width: @pdf.bounds.width * 0.45) do
        @pdf.text clean(@title), size: 11, style: :bold, color: brand, align: :right
        @pdf.text clean("Generated #{Fmt.datetime(Time.current)} by #{@user.name}"), size: 7.5, color: MUTED, align: :right
      end
      @pdf.move_cursor_to [ top - 44, @pdf.cursor ].min
      @pdf.stroke_color LINE
      @pdf.stroke_horizontal_rule
      @pdf.move_down 10
    end

    def company_line
      [ @company.address, @company.city, @company.phone.presence&.then { "Ph #{it}" }, @company.ntn.presence&.then { "NTN #{it}" } ].compact_blank.join(" - ")
    end

    def meta_lines
      @meta.each { |line| @pdf.text clean(line), size: 8.5, color: "344054" }
      @pdf.move_down 6 if @meta.any?
    end

    def summary_boxes
      return if @summary.empty?

      width = @pdf.bounds.width / @summary.size
      top = @pdf.cursor
      @summary.each_with_index do |(label, value), i|
        x = i * width
        @pdf.fill_color "F4F5F7"
        @pdf.fill_rectangle [ x, top ], width - 6, 30
        @pdf.fill_color MUTED
        @pdf.text_box clean(label), at: [ x + 7, top - 5 ], width: width - 18, size: 7.5, overflow: :shrink_to_fit
        @pdf.fill_color INK
        @pdf.text_box clean(value), at: [ x + 7, top - 15 ], width: width - 18, size: 11, style: :bold, overflow: :shrink_to_fit
      end
      @pdf.move_down 40
    end

    def table
      header_row = @columns.map { |c| { content: clean(c[:label]), font_style: :bold, text_color: "344054", align: c[:align] || :left } }
      body = @rows.each_with_index.map do |row, i|
        color = @flagged.include?(i) ? FLAG : INK
        row.each_with_index.map { |cell, j| { content: clean(cell), text_color: color, align: @columns[j][:align] || :left } }
      end
      body << [ { content: "No records match these filters.", colspan: @columns.size, text_color: MUTED } ] if body.empty?
      body << @totals.each_with_index.map { |cell, j| { content: clean(cell), font_style: :bold, align: @columns[j][:align] || :left } } if @totals

      total_weight = @columns.sum { |c| c[:width] }
      widths = @columns.map { |c| @pdf.bounds.width * c[:width] / total_weight }
      totals = @totals

      @pdf.table([ header_row ] + body, header: true, width: @pdf.bounds.width, column_widths: widths,
        row_colors: [ "FFFFFF", "F9FAFB" ],
        cell_style: { size: 8, padding: [ 4, 4 ], borders: [], overflow: :truncate, single_line: true }) do |t|
        t.row(0).background_color = "EEF0F3"
        if totals
          t.row(-1).borders = [ :top ]
          t.row(-1).border_color = "98A2B3"
          t.row(-1).background_color = "FFFFFF"
        end
      end
    end

    def after_lines
      return if @after.empty?

      @pdf.move_down 10
      @after.each { |line| @pdf.text clean(line), size: 9, style: :bold, color: INK }
    end

    def footer
      @pdf.repeat(:all, dynamic: true) do
        @pdf.stroke_color LINE
        @pdf.stroke_line [ 0, -10 ], [ @pdf.bounds.width, -10 ]
        @pdf.fill_color MUTED
        @pdf.text_box clean(@footer), at: [ 0, -16 ], width: @pdf.bounds.width * 0.75, height: 12, size: 7.5, single_line: true, overflow: :truncate
        @pdf.text_box "Page #{@pdf.page_number} of #{@pdf.page_count}", at: [ @pdf.bounds.width * 0.75, -16 ], width: @pdf.bounds.width * 0.25, height: 12, size: 7.5, align: :right
        @pdf.fill_color INK
      end
    end

    def logo_io
      return unless @company.logo.attached? && @company.logo.blob.content_type.in?(LOGO_TYPES)

      StringIO.new(@company.logo.download)
    rescue ActiveStorage::FileNotFoundError
      nil
    end
end
