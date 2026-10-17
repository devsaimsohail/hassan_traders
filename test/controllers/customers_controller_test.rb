require "test_helper"

class CustomersControllerTest < ActionDispatch::IntegrationTest
  def list(params = {})
    CustomerList.new(companies(:hassan).customers.with_balances, ActionController::Parameters.new(params))
  end

  test "the list sorts by udhaar and has the spec's tabs" do
    assert_equal [ "Khan Brothers", "Haq Bahu Collection", "Rehman Cloth House" ], list.rows.map(&:name)
    assert_equal({ "all" => 3, "udhaar" => 2, "overdue" => 0, "over_limit" => 1 }, list.tab_counts)
    assert_equal [ "Customers", "3" ], list.totals.first
    assert_equal "Rs 8,60,000", list.totals[1][1]
  end

  test "an accountant adds a customer with an opening balance" do
    sign_in_as users(:accountant)
    post customers_path, params: { customer: { name: "Zam Zam Bedsheets", city: "Hyderabad", credit_limit: 1200000, terms_days: 30, opening_balance: 260000 } }

    customer = Customer.find_by!(name: "Zam Zam Bedsheets")
    assert_redirected_to customer_path(customer)
    assert_equal [ "C04", 260_000, 1_200_000 ], [ customer.code, customer.opening_balance, customer.credit_limit ]
    assert_equal "Added customer Zam Zam Bedsheets (C04) with opening balance Rs 2,60,000", ActivityLog.order(:id).last.detail
  end

  test "only a partner can change the credit limit, and it is logged" do
    sign_in_as users(:accountant)
    patch customer_path(customers(:khan)), params: { customer: { credit_limit: 9_000_000, phone: "0333-1112223" } }
    customers(:khan).reload
    assert_equal [ 1_500_000, "0333-1112223" ], [ customers(:khan).credit_limit, customers(:khan).phone ]

    sign_in_as users(:partner)
    patch customer_path(customers(:khan)), params: { customer: { credit_limit: 700_000 } }
    assert_equal 700_000, customers(:khan).reload.credit_limit
    assert_equal "Changed credit limit for Khan Brothers: Rs 15,00,000 → Rs 7,00,000", ActivityLog.order(:id).last.detail
  end

  test "opening balance can't change after the customer is added" do
    sign_in_as users(:partner)
    patch customer_path(customers(:khan)), params: { customer: { opening_balance: 1 } }

    assert_equal 520_000, customers(:khan).reload.opening_balance
  end

  test "sales officers can view, store staff can't" do
    sign_in_as users(:sales)
    get customer_path(customers(:haq))
    assert_response :success
    assert_select "span", text: "Over credit limit"

    post customers_path, params: { customer: { name: "X" } }
    assert_response :forbidden

    sign_in_as users(:store)
    get customers_path
    assert_response :forbidden
  end

  test "PDF and company scoping" do
    sign_in_as users(:partner)
    get customers_path(format: :pdf, tab: "over_limit")
    assert_match "customer-balances-show-over-credit-limit.pdf", response.headers["Content-Disposition"]

    get customer_path(customers(:other_customer))
    assert_response :not_found
  end
end
