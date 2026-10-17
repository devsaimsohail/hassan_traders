class PaymentsController < ApplicationController
  include ListPdfDownload

  before_action :set_payment, only: %i[ show reverse ]
  rescue_from Payment::NotAllowed, with: ->(e) { redirect_to payment_path(@payment), alert: e.message }

  def index
    authorize Payment
    @list = PaymentList.new(PaymentList.base(Current.company), params)

    respond_to do |format|
      format.html
      format.pdf { send_list_pdf(@list) }
    end
  end

  def show
    respond_to do |format|
      format.html { @customer = Customer.with_balances.find(@payment.customer_id) }
      format.pdf do
        ActivityLog.record!(action: "Downloaded PDF", section: "Reports", ref: @payment.number, detail: "Downloaded receipt #{@payment.number} for #{@payment.customer.name}")
        send_data ReceiptPdf.new(@payment, user: Current.user).render,
          filename: "receipt-#{@payment.number.downcase}-#{@payment.customer.name.parameterize}.pdf", type: "application/pdf", disposition: "attachment"
      end
    end
  end

  def new
    authorize Payment
    invoice = Current.company.invoices.find_by(id: params[:invoice_id])
    @payment = Current.company.payments.new(date: Date.current, method: "cash", customer_id: invoice&.customer_id || params[:customer_id], invoice:)
    @payment.amount = Invoice.with_status.find(invoice.id).balance if invoice
  end

  def create
    authorize Payment
    @payment = Payment.receive!(company: Current.company, by: Current.user, **payment_params.to_h.symbolize_keys)

    if @payment.persisted?
      redirect_to payment_path(@payment), notice: "Saved. #{Fmt.rs(@payment.amount)} is added to #{@payment.customer.name}'s khata as jama."
    else
      render :new, status: :unprocessable_content
    end
  end

  def reverse
    @payment.reverse!(by: Current.user, reason: params[:reason])
    redirect_to payment_path(@payment), notice: "Receipt reversed. #{Fmt.rs(@payment.amount)} is back on #{@payment.customer.name}'s udhaar."
  end

  private
    def set_payment
      @payment = Current.company.payments.includes(:customer, :invoice, :received_by).find(params[:id])
      authorize @payment, :"#{action_name}?"
    end

    def payment_params
      attrs = params.require(:payment).permit(:customer_id, :against_choice, :amount, :method, :ref, :date)
      choice = attrs.delete(:against_choice).to_s
      customer = Current.company.customers.find_by(id: attrs[:customer_id])
      attrs.merge(customer:, customer_id: nil).merge(
        if choice.start_with?("invoice:") then { against: "bill", invoice: Current.company.invoices.find_by(id: choice.delete_prefix("invoice:")) }
        elsif choice.start_with?("opening_balance") then { against: "opening_balance" }
        else { against: "on_account" }
        end
      ).compact
    end
end
