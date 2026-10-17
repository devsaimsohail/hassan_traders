class PurchaseOrdersController < ApplicationController
  include ListPdfDownload

  before_action :set_purchase_order, except: %i[ index new create ]
  rescue_from PurchaseOrder::NotAllowed, with: ->(e) { redirect_to purchase_order_path(@purchase_order), alert: e.message }

  def index
    authorize PurchaseOrder
    @list = PurchaseOrderList.new(PurchaseOrderList.base(Current.company), params)

    respond_to do |format|
      format.html
      format.pdf { send_list_pdf(@list) }
    end
  end

  def show
    respond_to do |format|
      format.html do
        @moves = Current.company.stock_moves.where(ref: @purchase_order.number).includes(:item, :user).order(:id)
        @payments = @purchase_order.supplier_payments.includes(:user).order(:date, :id)
      end
      format.pdf do
        @purchase_order.log!(Current.user, "Downloaded PDF", "Downloaded purchase order PDF", section: "Reports")
        send_data PurchaseOrderPdf.new(@purchase_order, user: Current.user).render,
          filename: "#{@purchase_order.number.downcase}-#{@purchase_order.supplier.name.parameterize}.pdf", type: "application/pdf", disposition: "attachment"
      end
    end
  end

  def new
    @purchase_order = build_new
    authorize @purchase_order
  end

  def create
    @purchase_order = Current.company.purchase_orders.new(purchase_order_params.merge(created_by: Current.user, status: "draft"))
    authorize @purchase_order

    if @purchase_order.save
      if params[:send].present?
        @purchase_order.submit!(by: Current.user)
        redirect_to purchase_order_path(@purchase_order), notice: sent_notice
      else
        @purchase_order.log!(Current.user, "Created", "Saved draft PO for #{@purchase_order.supplier.name} — #{Fmt.rs(@purchase_order.total)}")
        redirect_to purchase_order_path(@purchase_order), notice: "Saved as a draft. Only you and the partners can see it until you send it."
      end
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @purchase_order.update(purchase_order_params)
      @purchase_order.log!(Current.user, "Edited", "Edited draft PO — #{Fmt.rs(@purchase_order.total)}")
      if params[:send].present?
        @purchase_order.submit!(by: Current.user)
        redirect_to purchase_order_path(@purchase_order), notice: sent_notice
      else
        redirect_to purchase_order_path(@purchase_order), notice: "Draft saved."
      end
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @purchase_order.discard!(by: Current.user)
    redirect_to purchase_orders_path, notice: "Draft deleted.", status: :see_other
  end

  def submit
    @purchase_order.submit!(by: Current.user)
    redirect_to purchase_order_path(@purchase_order), notice: sent_notice
  end

  def approve
    @purchase_order.approve!(by: Current.user)
    redirect_to purchase_order_path(@purchase_order), notice: "Approved. The godown can receive the goods now."
  end

  def receive
    on = Date.iso8601(params[:received_on].to_s) rescue Date.current
    changes = @purchase_order.receive!(by: Current.user, on:)
    flash[:price_changes] = changes.map do |c|
      { "item_id" => c.item.id, "name" => c.item.name, "old" => c.old_rate.to_s, "new" => c.new_rate.to_s, "percent" => c.percent.to_s,
        "avg" => c.avg_cost.to_s, "product" => c.item.product?, "sale_price" => c.item.sale_price }
    end
    redirect_to purchase_order_path(@purchase_order), notice: "Goods received. Stock and average cost are updated."
  end

  def pay
    @payment = @purchase_order.pay!(by: Current.user, **payment_params.to_h.symbolize_keys)
    if @payment.persisted?
      redirect_to purchase_order_path(@purchase_order), notice: "Payment of #{Fmt.rs(@payment.amount)} to #{@purchase_order.supplier.name} saved."
    else
      redirect_to purchase_order_path(@purchase_order, anchor: "pay"), alert: @payment.errors.full_messages.to_sentence
    end
  end

  def cancel
    @purchase_order.cancel!(by: Current.user, reason: params[:reason])
    redirect_to purchase_order_path(@purchase_order), notice: "#{@purchase_order.number} is cancelled. Stock did not change."
  end

  def copy
    @purchase_order = @purchase_order.copy_for(Current.user)
    render :new
  end

  private
    def set_purchase_order
      @purchase_order = Current.company.purchase_orders.includes(lines: :item).find(params[:id])
      authorize @purchase_order, :"#{action_name}?"
    end

    def build_new
      po = Current.company.purchase_orders.new(date: Date.current, created_by: Current.user)
      if (item = Current.company.items.find_by(id: params[:item_id]))
        po.supplier = item.default_supplier
        po.lines.build(item:, rate: item.last_purchase_rate || item.rate)
      end
      po
    end

    def purchase_order_params
      params.require(:purchase_order).permit(:supplier_id, :date, :note, lines_attributes: [ :id, :item_id, :qty, :rate, :_destroy ])
    end

    def payment_params
      params.require(:payment).permit(:amount, :method, :ref, :date)
    end

    def sent_notice
      @purchase_order.approved? ? "Saved and approved. The godown can receive the goods now." : "Sent to the partners for approval."
    end
end
