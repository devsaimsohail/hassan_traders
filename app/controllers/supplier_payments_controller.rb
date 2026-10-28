class SupplierPaymentsController < ApplicationController
  include ListPdfDownload

  def index
    authorize SupplierPayment
    @list = SupplierPaymentList.new(Current.company, params)

    respond_to do |format|
      format.html
      format.pdf { send_list_pdf(@list) }
    end
  end
end
