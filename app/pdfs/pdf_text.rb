module PdfText
  module_function

  def clean(value)
    value.to_s.gsub("→", "->").gsub("✓", "OK")
      .encode("Windows-1252", invalid: :replace, undef: :replace, replace: "")
      .encode("UTF-8")
  end
end
