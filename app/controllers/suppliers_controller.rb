class SuppliersController < ApplicationController
  include ListPdfDownload

  before_action :set_supplier, only: %i[ edit update ]

  def index
    authorize Supplier
    @list = SupplierList.new(SupplierList.base(Current.company), params)

    respond_to do |format|
      format.html
      format.pdf { send_list_pdf(@list) }
    end
  end

  def new
    @supplier = Current.company.suppliers.new
    authorize @supplier
  end

  def create
    @supplier = Current.company.suppliers.new(supplier_params)
    authorize @supplier

    if @supplier.save
      ActivityLog.record!(action: "Created", section: "Purchase", ref: @supplier.code, detail: "Added supplier #{@supplier.name}")
      redirect_to params[:return_to].presence_in([ new_purchase_order_path ]) || suppliers_path, notice: "#{@supplier.name} is added."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    @supplier.assign_attributes(supplier_params)
    changes = @supplier.changes_to_save.slice("name", "city", "phone", "supplies")

    if @supplier.save
      if changes.any?
        ActivityLog.record!(action: "Edited", section: "Purchase", ref: @supplier.code, detail: "Changed #{changes.keys.to_sentence} for supplier #{@supplier.name}",
          old_value: changes.transform_values(&:first), new_value: changes.transform_values(&:last))
      end
      redirect_to suppliers_path, notice: "Saved."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private
    def set_supplier
      @supplier = Current.company.suppliers.find(params[:id])
      authorize @supplier
    end

    def supplier_params
      params.require(:supplier).permit(:name, :city, :phone, :supplies)
    end
end
