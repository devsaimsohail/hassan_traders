class InvoicesController < ApplicationController
  include ListPdfDownload

  before_action :set_invoice, except: :index
  rescue_from Invoice::NotAllowed, with: ->(e) { redirect_to invoice_path(@invoice), alert: e.message }

  def index
    authorize Invoice
    @list = InvoiceList.new(InvoiceList.base(Current.company), params)

    respond_to do |format|
      format.html
      format.pdf { send_list_pdf(@list) }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.pdf do
        ActivityLog.record!(action: "Downloaded PDF", section: "Reports", ref: @invoice.number, detail: "Downloaded bill #{@invoice.number} for #{@invoice.customer.name}")
        send_data InvoicePdf.new(@invoice, user: Current.user).render,
          filename: "bill-#{@invoice.number.downcase}-#{@invoice.customer.name.parameterize}.pdf", type: "application/pdf", disposition: "attachment"
      end
    end
  end

  def extend_due
    to = Date.iso8601(params[:due_date].to_s) rescue nil
    @invoice.extend_due!(by: Current.user, to:)
    redirect_to invoice_path(@invoice), notice: "Due date moved to #{Fmt.date(to)}."
  end

  def cancel
    @invoice.cancel!(by: Current.user, reason: params[:reason])
    redirect_to invoice_path(@invoice), notice: "Bill #{@invoice.number} is cancelled and removed from the customer's udhaar."
  end

  private
    def set_invoice
      @invoice = Current.company.invoices.with_status.includes(:customer, :sales_order, lines: :item).find(params[:id])
      authorize @invoice, :"#{action_name}?"
    end
end
