module ListPdfDownload
  extend ActiveSupport::Concern

  private
    def send_list_pdf(list)
      pdf = ListPdf.new(list, company: Current.company, user: Current.user)
      filters = list.filters_text.presence&.join(", ") || "no filters"
      ActivityLog.record!(action: "Downloaded PDF", section: "Reports", detail: "Downloaded #{list.title} (#{filters})")
      send_data pdf.render, filename: pdf.filename, type: "application/pdf", disposition: "attachment"
    end
end
