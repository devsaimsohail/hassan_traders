class CompaniesController < ApplicationController
  LABELS = {
    "name" => "company name", "brand_color" => "brand colour", "legal_name" => "registered name", "ntn" => "NTN",
    "strn" => "STRN", "address" => "address", "city" => "city", "phone" => "phone", "mobile" => "mobile",
    "email" => "email", "fiscal_year_start" => "financial year start", "logo" => "logo"
  }.freeze

  def update
    @company = Current.company
    authorize @company

    removing = params.dig(:company, :remove_logo) == "1" && company_params[:logo].blank? && @company.logo.attached?
    @company.assign_attributes(company_params)
    changes = @company.changes_to_save.slice(*Company::PROFILE_FIELDS)
    changes["logo"] = [ nil, "new logo" ] if company_params[:logo].present?
    changes["logo"] = [ "logo", "removed" ] if removing

    if @company.save
      @company.logo.purge_later if removing
      log_changes(changes)
      redirect_to settings_path, notice: changes.any? ? "Saved. Both partners see the change now." : "Nothing changed."
    else
      redirect_to settings_path, alert: @company.errors.full_messages.to_sentence
    end
  end

  private
    def company_params
      params.require(:company).permit(*Company::PROFILE_FIELDS, :logo)
    end

    def log_changes(changes)
      return if changes.empty?

      ActivityLog.record!(
        action: "Edited", section: "Settings",
        detail: "Changed #{changes.keys.map { |k| LABELS[k] }.to_sentence}",
        old_value: changes.transform_values(&:first), new_value: changes.transform_values(&:last)
      )
    end
end
