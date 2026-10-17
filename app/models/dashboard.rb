class Dashboard
  Month = Data.define(:start, :sales, :received, :purchases) do
    def label(today) = start.strftime("%b") + (start == today.beginning_of_month ? " (1–#{today.day})" : "")
  end
  Debtor = Data.define(:customer_id, :name, :city, :balance, :overdue, :credit_limit)

  attr_reader :company, :today

  def initialize(company, today: Date.current)
    @company = company
    @today = today
  end

  def this_month = today.beginning_of_month..today

  def same_days_last_month
    start = today.prev_month.beginning_of_month
    start..[ start + (today.day - 1), start.end_of_month ].min
  end

  def sales_this = @sales_this ||= sales_between(this_month)
  def sales_prev = @sales_prev ||= sales_between(same_days_last_month)
  def received_this = @received_this ||= received_between(this_month)
  def received_prev = @received_prev ||= received_between(same_days_last_month)
  def sales_change = change(sales_this, sales_prev)
  def received_change = change(received_this, received_prev)

  def receivable = customer_sums[0]
  def past_due = customer_sums[1]

  def payable
    @payable ||= company.purchase_orders.where(status: "received").sum(:total) -
      company.supplier_payments.joins(:purchase_order).merge(PurchaseOrder.where(status: "received")).sum(:amount)
  end

  def stock_value = @stock_value ||= company.items.with_stock.sum("GREATEST(items.value, 0)")

  def overdue_bills
    @overdue_bills ||= company.invoices.with_status(today).where(status: "Overdue").pick(Arel.sql("COUNT(*), COALESCE(SUM(invoices.balance), 0)"))
  end

  def pending_orders
    @pending_orders ||= company.sales_orders.where(status: "pending").pick(Arel.sql("COUNT(*), COALESCE(SUM(amount), 0)"))
  end

  def stock_alerts
    @stock_alerts ||= company.items.with_stock.where.not(status: "OK").group(:status).count
  end

  def top_debtors(limit = 8)
    company.customers.with_balances(today).where("customers.balance > 0").reorder("customers.balance DESC").limit(limit)
      .map { |c| Debtor.new(customer_id: c.id, name: c.name, city: c.city, balance: c.balance.to_i, overdue: c.overdue.to_i, credit_limit: c.credit_limit) }
  end

  def months(count = 6)
    first = (today << (count - 1)).beginning_of_month
    range = first..today
    sales = by_month(company.invoices.where(cancelled_at: nil, date: range), "date", "amount")
    received = by_month(company.payments.live.where(date: range), "date", "amount")
    purchases = by_month(company.purchase_orders.where.not(status: %w[draft cancelled]).where(date: range), "date", "total")
    (0...count).map do |i|
      start = (first >> i)
      Month.new(start:, sales: sales.fetch(start, 0), received: received.fetch(start, 0), purchases: purchases.fetch(start, 0))
    end
  end

  private
    def sales_between(range) = company.invoices.where(cancelled_at: nil, date: range).sum(:amount)
    def received_between(range) = company.payments.live.where(date: range).sum(:amount)

    def change(now, before)
      return nil if before.zero?

      ((now - before) * 100.0 / before).round(1)
    end

    def customer_sums
      @customer_sums ||= company.customers.with_balances(today).pick(Arel.sql("COALESCE(SUM(customers.balance), 0), COALESCE(SUM(customers.overdue), 0)"))
    end

    def by_month(scope, date_column, sum_column)
      scope.group(Arel.sql("date_trunc('month', #{date_column})::date")).sum(sum_column)
    end
end
