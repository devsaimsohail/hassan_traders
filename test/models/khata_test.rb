require "test_helper"

class KhataTest < ActiveSupport::TestCase
  setup do
    @khan = customers(:khan)
    @khan.update_columns(created_at: Time.zone.local(2026, 5, 1))
    so = companies(:hassan).sales_orders.create!(customer: @khan, date: Date.new(2026, 9, 1), booked_by: users(:sales),
      lines_attributes: [ { item_id: items(:suit).id, qty: 10, rate: 3400 } ])
    @bill = so.dispatch!(by: users(:store), on: Date.new(2026, 9, 1))
    @pay = Payment.receive!(company: companies(:hassan), by: users(:accountant), customer: @khan, against: "opening_balance",
      amount: 100_000, method: "cheque", ref: "Chq #1 · HBL", date: Date.new(2026, 9, 10))
    @cash = Payment.receive!(company: companies(:hassan), by: users(:accountant), customer: @khan, invoice: @bill,
      amount: 20_000, method: "cash", date: Date.new(2026, 10, 2))
  end

  test "entries in date order with a running balance" do
    k = Khata.new(@khan)
    assert_equal [ [ "B/F", 520_000, 0, 520_000 ], [ "Naam", 34_000, 0, 554_000 ], [ "Jama", 0, 100_000, 454_000 ], [ "Jama", 0, 20_000, 434_000 ] ],
      k.entries.map { |e| [ e.type, e.naam, e.jama, e.balance ] }
    assert_equal Customer.with_balances.find(@khan.id).balance, k.closing
  end

  test "a period starts from the balance brought forward" do
    k = Khata.new(@khan, from: Date.new(2026, 10, 1), to: Date.new(2026, 10, 31))
    assert_equal [ 454_000, 0, 20_000, 434_000 ], [ k.opening, k.naam, k.jama, k.closing ]
    assert_equal [ @cash.number ], k.entries.map(&:ref)
  end

  test "reversed payments and cancelled bills show both lines" do
    travel_to Time.zone.local(2026, 10, 15) do
      @pay.reverse!(by: users(:partner), reason: "Cheque bounced")
      @bill.cancel!(by: users(:partner), reason: "Wrong rate")
    end
    k = Khata.new(@khan)

    assert_equal [ "Receipt reversed — Cheque bounced", "Bill cancelled — Wrong rate" ].sort, k.entries.last(2).map(&:detail).sort
    assert_equal Customer.with_balances.find(@khan.id).balance, k.closing
  end
end
