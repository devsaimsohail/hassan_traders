class CustomersController < ApplicationController
  include ListPdfDownload

  before_action :set_customer, only: %i[ show edit update ]

  def index
    authorize Customer
    @list = CustomerList.new(Current.company.customers.with_balances, params)

    respond_to do |format|
      format.html
      format.pdf { send_list_pdf(@list) }
    end
  end

  def show
  end

  def new
    @customer = Current.company.customers.new(terms_days: 30)
    authorize @customer
  end

  def create
    @customer = Current.company.customers.new(customer_params(creating: true))
    authorize @customer

    if @customer.save
      ActivityLog.record!(action: "Created", section: "Customers", ref: @customer.code,
        detail: "Added customer #{@customer.name} (#{@customer.code})#{" with opening balance #{Fmt.rs(@customer.opening_balance)}" if @customer.opening_balance.positive?}")
      redirect_to customer_path(@customer), notice: "#{@customer.name} is added."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    @customer.assign_attributes(customer_params)
    changes = @customer.changes_to_save.slice(*Customer::EDITABLE)

    if @customer.save
      log_changes(changes)
      redirect_to customer_path(@customer), notice: changes.any? ? "Saved." : "Nothing changed."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private
    def set_customer
      @customer = Current.company.customers.with_balances.find(params[:id])
      authorize @customer
    end

    def customer_params(creating: false)
      fields = %i[name city area phone terms_days note]
      fields << :credit_limit if creating || policy(@customer || Customer).change_credit_limit?
      fields << :opening_balance if creating
      params.require(:customer).permit(*fields)
    end

    def log_changes(changes)
      return if changes.empty?

      labels = { "credit_limit" => "credit limit", "terms_days" => "payment terms", "phone" => "mobile" }
      ActivityLog.record!(action: "Edited", section: "Customers", ref: @customer.code,
        detail: "Changed #{changes.keys.map { |k| labels.fetch(k, k) }.to_sentence} for #{@customer.name}" +
          (changes["credit_limit"] ? ": #{Fmt.rs(changes["credit_limit"].first)} → #{Fmt.rs(changes["credit_limit"].last)}" : ""),
        old_value: changes.transform_values(&:first), new_value: changes.transform_values(&:last))
    end
end
