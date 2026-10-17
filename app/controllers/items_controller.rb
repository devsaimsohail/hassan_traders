class ItemsController < ApplicationController
  include ListPdfDownload

  before_action :set_item, only: %i[ show edit update ]

  def index
    authorize Item
    @list = StockList.new(Current.company.items.with_stock, params)

    respond_to do |format|
      format.html
      format.pdf { send_list_pdf(@list) }
    end
  end

  def show
    @moves = @item.stock_moves.includes(:user).order(date: :desc, id: :desc)

    respond_to do |format|
      format.html
      format.pdf do
        ActivityLog.record!(action: "Downloaded PDF", section: "Reports", ref: @item.code, detail: "Downloaded stock card for #{@item.name}")
        send_data StockCardPdf.new(@item, @moves.reverse, company: Current.company, user: Current.user).render,
          filename: "stock-card-#{@item.name.parameterize}.pdf", type: "application/pdf", disposition: "attachment"
      end
    end
  end

  def new
    @item = Current.company.items.new(category: params[:category].presence_in(Item::CATEGORIES.keys) || "raw_material")
    authorize @item
  end

  def create
    @item = Current.company.items.new(item_params)
    authorize @item

    if @item.save
      ActivityLog.record!(action: "Created", section: "Stock", ref: @item.code, detail: "Added item #{@item.name} (#{@item.code})")
      redirect_to item_path(@item), notice: "#{@item.name} is added."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    @item.assign_attributes(item_params)
    changes = @item.changes_to_save.slice(*Item::EDITABLE)

    if @item.save
      if changes.any?
        ActivityLog.record!(action: "Edited", section: "Stock", ref: @item.code,
          detail: "Changed #{changes.keys.map { |k| Item.human_attribute_name(k).downcase }.to_sentence} for #{@item.name}",
          old_value: changes.transform_values(&:first), new_value: changes.transform_values(&:last))
      end
      redirect_to item_path(@item), notice: changes.any? ? "Saved." : "Nothing changed."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private
    def set_item
      @item = Current.company.items.with_stock.find(params[:id])
      authorize @item
    end

    def item_params
      params.require(:item).permit(:name, :category, :unit, :rate, :sale_price, :reorder_level, :opening_qty)
    end
end
