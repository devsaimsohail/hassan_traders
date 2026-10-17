module DatePreset
  PRESETS = {
    "all" => "All dates", "today" => "Today", "week" => "This week", "month" => "This month",
    "last_month" => "Last month", "3m" => "Last 3 months", "custom" => "Pick dates…"
  }.freeze

  module_function

  def range(preset, from = nil, to = nil, today: Date.current)
    case preset
    when "today" then [ today, today ]
    when "week" then [ today.beginning_of_week, today ]
    when "month" then [ today.beginning_of_month, today ]
    when "last_month" then [ today.prev_month.beginning_of_month, today.prev_month.end_of_month ]
    when "3m" then [ (today << 2).beginning_of_month, today ]
    when "custom" then [ parse(from), parse(to) ]
    else [ nil, nil ]
    end
  end

  def text(from, to)
    return "All dates" unless from || to

    "#{from ? Fmt.date(from) : "start"} to #{to ? Fmt.date(to) : "today"}"
  end

  def parse(value)
    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
  end
end
