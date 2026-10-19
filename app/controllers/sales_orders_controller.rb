class SalesOrdersController < ApplicationController
  include ListPdfDownload

  before_action :set_sales_order, except: %i[ index new create ]
  rescue_from SalesOrder::NotAllowed, with: ->(e) { redirect_to sales_order_path(@sales_order), alert: e.message }

  def index
    authorize SalesOrder
    @list = SalesOrderList.new(SalesOrderList.base(Current.company), params)

    respond_to do |format|
      format.html
      format.pdf { send_list_pdf(@list) }
    end
  end

  def show
    respond_to do |format|
      format.html { @moves = Current.company.stock_moves.where(ref: @sales_order.number).includes(:item, :user).order(:id) }
      format.pdf do
        @sales_order.log!(Current.user, "Downloaded PDF", "Downloaded sales order PDF", section: "Reports")
        send_data SalesOrderPdf.new(@sales_order, user: Current.user).render,
          filename: "#{@sales_order.number.downcase}-#{@sales_order.customer.name.parameterize}.pdf", type: "application/pdf", disposition: "attachment"
      end
    end
  end

  def new
    @sales_order = Current.company.sales_orders.new(date: Date.current, booked_by: Current.user, customer_id: params[:customer_id])
    authorize @sales_order
  end

  def create
    @sales_order = Current.company.sales_orders.new(sales_order_params.merge(booked_by: Current.user, status: "pending"))
    authorize @sales_order

    if @sales_order.save
      @sales_order.book!(by: Current.user)
      redirect_to sales_order_path(@sales_order), notice: "Order booked. The godown can dispatch it now."
    else
      render :new, status: :unprocessable_content
    end
  end

  def dispatch_goods
    on = Date.iso8601(params[:dispatched_on].to_s) rescue Date.current
    invoice = @sales_order.dispatch!(by: Current.user, on:)
    redirect_to sales_order_path(@sales_order), notice: "Dispatched. Stock is updated and bill #{invoice.number} is made, due #{Fmt.date(invoice.due_date)}."
  end

  def deliver
    @sales_order.deliver!(by: Current.user)
    redirect_to sales_order_path(@sales_order), notice: "Marked as delivered."
  end

  def cancel
    @sales_order.cancel!(by: Current.user, reason: params[:reason])
    redirect_to sales_order_path(@sales_order), notice: "#{@sales_order.number} is cancelled."
  end

  private
    def set_sales_order
      @sales_order = Current.company.sales_orders.includes(:customer, lines: :item).find(params[:id])
      authorize @sales_order, { "dispatch_goods" => :dispatch? }.fetch(action_name, :"#{action_name}?")
    end

    def sales_order_params
      params.require(:sales_order).permit(:customer_id, :date, :note, lines_attributes: [ :item_id, :qty, :rate ])
    end
end
