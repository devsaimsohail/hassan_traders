class UnitsController < ApplicationController
  include ListPdfDownload

  before_action :set_unit, only: %i[ edit update destroy ]

  def index
    authorize Unit
    @list = UnitList.new(UnitList.base(Current.company), params)

    respond_to do |format|
      format.html
      format.pdf { send_list_pdf(@list) }
    end
  end

  def new
    @unit = Current.company.units.new
    authorize @unit
  end

  def create
    @unit = Current.company.units.new(unit_params)
    authorize @unit

    Unit.transaction do
      @unit.save!
      ActivityLog.record!(action: "Created", section: "Stock", detail: "Added unit #{@unit.name}")
    end
    redirect_to params[:return_to].presence_in([ new_item_path ]) || units_path, notice: "#{@unit.name} is added."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_content
  end

  def edit
  end

  def update
    old_name = @unit.name
    @unit.assign_attributes(unit_params)
    return redirect_to(units_path, notice: "Nothing changed.") unless @unit.will_save_change_to_name?

    Unit.transaction do
      count = @unit.items.count
      @unit.save!
      ActivityLog.record!(action: "Edited", section: "Stock", detail: "Renamed unit #{old_name} to #{@unit.name}#{" on #{count} #{"item".pluralize(count)}" if count.positive?}",
        old_value: { "name" => old_name }, new_value: { "name" => @unit.name })
    end
    redirect_to units_path, notice: "Saved."
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_content
  end

  def destroy
    Unit.transaction do
      @unit.destroy!
      ActivityLog.record!(action: "Deleted", section: "Stock", detail: "Deleted unit #{@unit.name}")
    end
    redirect_to units_path, notice: "#{@unit.name} is deleted."
  rescue ActiveRecord::RecordNotDestroyed
    redirect_to edit_unit_path(@unit), alert: @unit.errors.full_messages.to_sentence
  end

  private
    def set_unit
      @unit = Current.company.units.find(params[:id])
      authorize @unit
    end

    def unit_params
      params.require(:unit).permit(:name)
    end
end
