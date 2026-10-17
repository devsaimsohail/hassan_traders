class KhataController < ApplicationController
  def show
    authorize :khata, :show?
    @customers = Current.company.customers.with_balances.order(:name)
    @customer = Current.company.customers.find_by(id: params[:customer_id]) ||
      Current.company.customers.with_balances.reorder("customers.balance DESC").first
    @preset = DatePreset::PRESETS.key?(params[:preset]) ? params[:preset] : "all"
    from, to = DatePreset.range(@preset, params[:from], params[:to])
    @khata = @customer && Khata.new(@customer, from:, to:)

    respond_to do |format|
      format.html { @balance = @customer && Customer.with_balances.find(@customer.id) }
      format.pdf do
        ActivityLog.record!(action: "Downloaded PDF", section: "Reports", ref: @customer.code, detail: "Downloaded khata for #{@customer.name} (#{@khata.period_text})")
        send_data KhataPdf.new(@khata, user: Current.user).render,
          filename: "khata-#{@customer.name.parameterize}-#{@khata.period_text.parameterize}.pdf", type: "application/pdf", disposition: "attachment"
      end
    end
  end
end
