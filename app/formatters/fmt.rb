module Fmt
  module_function

  def rs(amount)
    return "" if amount.nil?

    "#{"-" if amount.to_d.negative?}Rs #{lakh(amount.to_d.abs.round)}"
  end

  def rate(amount)
    return "" if amount.nil?

    value = amount.to_d.round(2)
    paisa = value.frac.abs.zero? ? "" : format(".%02d", (value.frac.abs * 100).round)
    "#{"-" if value.negative?}Rs #{lakh(value.abs.truncate)}#{paisa}"
  end

  def qty(value)
    return "" if value.nil?

    number = value.to_d
    whole = lakh(number.truncate.abs)
    fraction = (number.abs - number.abs.truncate).to_s("F").sub(/\A0/, "").sub(/\.0\z/, "")
    "#{"-" if number.negative?}#{whole}#{fraction unless fraction == "."}"
  end

  def lakh(integer)
    digits = integer.to_i.to_s
    return digits if digits.length <= 3

    "#{digits[0...-3].reverse.scan(/\d{1,2}/).join(",").reverse},#{digits[-3..]}"
  end

  def date(value)
    value&.strftime("%-d %b %Y").to_s
  end

  def datetime(value)
    value&.in_time_zone&.strftime("%-d %b %Y, %-l:%M %P").to_s
  end
end
