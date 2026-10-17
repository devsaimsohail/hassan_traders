class Khata
  Entry = Data.define(:key, :date, :type, :ref, :detail, :naam, :jama, :balance, :record)

  attr_reader :customer, :from, :to

  def initialize(customer, from: nil, to: nil)
    @customer = customer
    @from = from
    @to = to
  end

  def entries
    @entries ||= all_entries.select { |e| (from.nil? || e.date >= from) && (to.nil? || e.date <= to) }
  end

  def opening
    before = all_entries.select { |e| from && e.date < from }
    before.any? ? before.last.balance : 0
  end

  def naam = entries.sum(&:naam)
  def jama = entries.sum(&:jama)
  def closing = opening + naam - jama
  def period_text = DatePreset.text(from, to)

  private
    def all_entries
      @all_entries ||= begin
        rows = raw_entries
        first_day = rows.map { |r| r[:date] }.min
        if customer.opening_balance.nonzero?
          day = [ customer.created_at.to_date, first_day ].compact.min
          rows.unshift({ key: "opening", date: day, sort: 0, type: "B/F", ref: "B/F", detail: "Opening balance", naam: customer.opening_balance, jama: 0, record: customer })
        end
        balance = 0
        rows.sort_by.with_index { |r, i| [ r[:date], r[:sort], i ] }.map do |r|
          balance += r[:naam] - r[:jama]
          Entry.new(key: r[:key], date: r[:date], type: r[:type], ref: r[:ref], detail: r[:detail], naam: r[:naam], jama: r[:jama], balance:, record: r[:record])
        end
      end
    end

    def raw_entries
      bills = customer.invoices.includes(:sales_order).order(:date, :id)
      payments = customer.payments.includes(:invoice).order(:date, :id)
      rows = bills.flat_map do |bill|
        line = { key: "bill-#{bill.id}", date: bill.date, sort: 1, type: "Naam", ref: bill.number,
                 detail: bill.sales_order ? "Bill against order #{bill.sales_order.number}" : "Bill", naam: bill.amount, jama: 0, record: bill }
        next [ line ] unless bill.cancelled?

        [ line, { key: "bill-cancel-#{bill.id}", date: bill.cancelled_at.to_date, sort: 3, type: "Jama", ref: bill.number,
                  detail: "Bill cancelled — #{bill.cancel_reason}", naam: 0, jama: bill.amount, record: bill } ]
      end
      rows + payments.flat_map do |pay|
        line = { key: "payment-#{pay.id}", date: pay.date, sort: 2, type: "Jama", ref: pay.number,
                 detail: [ pay.method_label, pay.ref.presence, "against #{pay.against_label}" ].compact.join(" · "), naam: 0, jama: pay.amount, record: pay }
        next [ line ] unless pay.reversed?

        [ line, { key: "payment-reverse-#{pay.id}", date: pay.reversed_at.to_date, sort: 3, type: "Naam", ref: pay.number,
                  detail: "Receipt reversed — #{pay.reverse_reason}", naam: pay.amount, jama: 0, record: pay } ]
      end
    end
end
