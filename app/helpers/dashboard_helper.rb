module DashboardHelper
  SERIES = [ [ :sales, "Sales", "var(--brand)" ], [ :received, "Received", "color-mix(in srgb, var(--brand) 40%, white)" ], [ :purchases, "Purchases", "#CDD5DF" ] ].freeze

  def change_text(change)
    return tag.span("no sales last month to compare", class: "text-muted") if change.nil?

    tag.span("#{"+" if change.positive?}#{change.to_d.to_s("F").delete_suffix(".0")}%", class: change.negative? ? "font-semibold text-bad" : "font-semibold text-ok")
  end

  def nice_step(raw)
    return 1 if raw <= 0

    magnitude = 10**Math.log10(raw).floor
    [ 1, 2, 2.5, 5, 10 ].map { |m| m * magnitude }.find { |s| s >= raw }
  end

  def month_chart(months, today)
    width = 720
    height = 230
    left = 64
    bottom = 26
    top = 8
    peak = months.flat_map { |m| [ m.sales, m.received, m.purchases ] }.max.to_f
    step = nice_step(peak / 4)
    max = [ step * 4, 1 ].max
    plot_h = height - bottom - top
    y = ->(v) { top + plot_h - (v.to_f / max * plot_h) }
    slot = (width - left) / months.size.to_f
    bar = [ (slot * 0.74) / 3, 26 ].min

    tag.svg(viewBox: "0 0 #{width} #{height}", width: "100%", role: "img", "aria-label": "Sales, received and purchases by month", class: "block") do
      safe_join(
        (0..4).map do |i|
          value = step * i
          safe_join([
            tag.line(x1: left, x2: width, y1: y.(value), y2: y.(value), stroke: i.zero? ? "#E7E9EE" : "#F1F3F6"),
            tag.text(i.zero? ? "0" : Fmt.short(value), x: left - 8, y: y.(value), dy: "0.32em", "text-anchor": "end", class: "fill-muted text-[11px]")
          ])
        end +
        months.each_with_index.map do |m, i|
          x0 = left + i * slot + (slot - bar * 3) / 2
          safe_join(SERIES.each_with_index.map do |(key, label, color), j|
            value = m.public_send(key)
            tag.rect(x: x0 + j * bar, y: y.(value), width: bar - 2, height: [ y.(0) - y.(value), 0 ].max, rx: 3, style: "fill: #{color}") do
              tag.title("#{label}, #{m.label(today)}: #{Fmt.rs(value)}")
            end
          end + [ tag.text(m.label(today), x: left + i * slot + slot / 2, y: height - 6, "text-anchor": "middle", class: "fill-muted text-[11px]") ])
        end
      )
    end
  end
end
