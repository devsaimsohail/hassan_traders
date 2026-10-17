class ListView
  PER_PAGE = 300
  DATE_PRESETS = {
    "all" => "All dates", "today" => "Today", "week" => "This week", "month" => "This month",
    "last_month" => "Last month", "3m" => "Last 3 months", "custom" => "Pick dates…"
  }.freeze

  Column = Struct.new(:key, :label, :sort, :format, :align, :optional, :pdf_width, :tones, keyword_init: true) do
    def right? = align == :right
  end
  Tab = Struct.new(:key, :label, :condition, keyword_init: true)
  Select = Struct.new(:key, :label, :all_label, :column, keyword_init: true)

  class_attribute :title, :columns, :tabs, :selects, :search_columns, :date_column, :default_preset,
    :default_sort, :pdf_landscape, :search_placeholder, :tab_group, instance_writer: false
  self.columns = []
  self.tabs = []
  self.selects = []
  self.search_columns = []
  self.default_preset = "all"
  self.pdf_landscape = false
  self.search_placeholder = "Search"
  self.tab_group = "Show"

  def self.column(key, label, **options) = self.columns += [ Column.new(key:, label:, **options) ]
  def self.tab(key, label, condition = nil) = self.tabs += [ Tab.new(key: key.to_s, label:, condition:) ]
  RESERVED_PARAMS = %w[action controller format q tab preset from to sort dir page].freeze

  def self.select(key, label, all_label:, column: key)
    raise ArgumentError, "#{key} is a reserved parameter" if RESERVED_PARAMS.include?(key.to_s)

    self.selects += [ Select.new(key: key.to_s, label:, all_label:, column:) ]
  end

  attr_reader :params

  def initialize(base_scope, params)
    @base = base_scope
    @params = params.permit(:q, :tab, :preset, :from, :to, :sort, :dir, :page, *selects.map(&:key)).to_h.symbolize_keys
  end

  def query = params[:q].to_s.strip
  def page = [ params[:page].to_i, 1 ].max
  def current_tab = tabs.find { |t| t.key == params[:tab] } || tabs.first
  def preset = DATE_PRESETS.key?(params[:preset]) ? params[:preset] : default_preset
  def selected(select) = params[select.key.to_sym].presence

  def date_range
    today = Date.current
    case preset
    when "today" then [ today, today ]
    when "week" then [ today.beginning_of_week, today ]
    when "month" then [ today.beginning_of_month, today ]
    when "last_month" then [ today.prev_month.beginning_of_month, today.prev_month.end_of_month ]
    when "3m" then [ (today << 2).beginning_of_month, today ]
    when "custom" then [ parse_date(params[:from]), parse_date(params[:to]) ]
    else [ nil, nil ]
    end
  end

  def filtered
    @filtered ||= begin
      scope = @base
      scope = search(scope) if query.present?
      scope = by_date(scope) if date_column
      selects.each { |s| scope = scope.where(s.column => selected(s)) if selected(s) }
      scope
    end
  end

  def scope
    @scope ||= apply_tab(filtered, current_tab)
  end

  def tab_counts
    @tab_counts ||= tabs.to_h { |t| [ t.key, apply_tab(filtered, t).count ] }
  end

  def rows
    @rows ||= sorted(scope).limit(PER_PAGE).offset((page - 1) * PER_PAGE).to_a
  end

  def all_rows
    sorted(scope).to_a
  end

  def total_count = @total_count ||= scope.count
  def more_pages? = page * PER_PAGE < total_count

  def options_for(select)
    @base.reorder(nil).distinct.where.not(select.column => [ nil, "" ]).order(select.column).pluck(select.column)
  end

  def sort_key = sortable(params[:sort]) ? params[:sort] : default_sort.first.to_s
  def sort_dir = %w[asc desc].include?(params[:dir]) && sortable(params[:sort]) ? params[:dir] : default_sort.last.to_s

  def sort_params_for(column)
    first = column.right? || column.format.in?([ :date, :datetime ]) ? "desc" : "asc"
    dir = sort_key == column.key.to_s ? (sort_dir == "asc" ? "desc" : "asc") : first
    url_params(sort: column.key, dir:, page: nil)
  end

  def url_params(overrides = {})
    params.merge(overrides).compact_blank
  end

  def filtering?
    query.present? || preset != default_preset || selects.any? { |s| selected(s) } || (tabs.any? && current_tab != tabs.first)
  end

  def filters_text
    texts = []
    texts << "Date: #{date_text}" if date_column
    selects.each { |s| texts << "#{s.label}: #{selected(s)}" if selected(s) }
    texts << "#{tab_group}: #{current_tab.label}" if tabs.any? && current_tab != tabs.first
    texts << "Search: \"#{query}\"" if query.present?
    texts
  end

  def date_text
    from, to = date_range
    return "All dates" unless from || to

    "#{from ? Fmt.date(from) : "start"} to #{to ? Fmt.date(to) : "today"}"
  end

  def value(row, column) = row.public_send(column.key)
  def flagged?(_row) = false
  def totals = [ [ "Records", Fmt.lakh(total_count) ] ]
  def pdf_columns = columns.select(&:pdf_width)
  def pdf_totals = nil

  private
    def sorted(scope) = scope.reorder(Arel.sql(order_sql))

    def sortable(key) = columns.any? { |c| c.key.to_s == key.to_s && c.sort }

    def order_sql
      column = columns.find { |c| c.key.to_s == sort_key }
      "#{column.sort} #{sort_dir.upcase} NULLS LAST, #{@base.table_name}.id DESC"
    end

    def search(scope)
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
      scope.where(search_columns.map { |c| "#{c} ILIKE :pattern" }.join(" OR "), pattern:)
    end

    def by_date(scope)
      from, to = date_range
      scope = scope.where(date_column => from.beginning_of_day..) if from
      scope = scope.where(date_column => ..to.end_of_day) if to
      scope
    end

    def apply_tab(scope, tab)
      tab&.condition ? tab.condition.call(scope) : scope
    end

    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end
end
