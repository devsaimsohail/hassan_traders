module ListsHelper
  def list_cell(list, row, column)
    value = list.value(row, column)
    case column.format
    when :rs then Fmt.rs(value)
    when :rate then Fmt.rate(value)
    when :qty then Fmt.qty(value)
    when :date then Fmt.date(value)
    when :datetime then Fmt.datetime(value)
    when :pill then value.present? ? pill(value, column.tones&.fetch(value, nil)) : ""
    else value
    end
  end

  def sort_marker(list, column)
    return unless list.sort_key == column.key.to_s

    list.sort_dir == "asc" ? " ↑" : " ↓"
  end

  def aria_sort(list, column)
    return "none" unless list.sort_key == column.key.to_s

    list.sort_dir == "asc" ? "ascending" : "descending"
  end

  def total_tone(tone)
    { bad: "text-bad", good: "text-ok", warn: "text-warn" }[tone]
  end
end
