require "test_helper"

class ActivityLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    ActivityLog.create!(company: companies(:hassan), user_name: "Bilal Ahmed", action: "Payment received", section: "Payments", detail: "Rs 50,000 cash from Khan Brothers")
    ActivityLog.create!(company: companies(:other), user_name: "Someone", action: "Edited", section: "Settings", detail: "Other company change")
  end

  test "a partner sees this company's log only" do
    sign_in_as users(:partner)
    get activity_logs_path

    assert_response :success
    assert_select "td", text: "Rs 50,000 cash from Khan Brothers"
    assert_select "td", text: "Other company change", count: 0
    assert_select "nav a", text: "Activity log"
  end

  test "an accountant can view the log" do
    sign_in_as users(:accountant)
    get activity_logs_path(q: "khan")

    assert_response :success
    assert_select "tbody tr", 1
  end

  test "store staff cannot see the log" do
    sign_in_as users(:store)
    get activity_logs_path

    assert_response :forbidden
  end

  test "the PDF follows the filters and the download is logged" do
    sign_in_as users(:partner)
    get activity_logs_path(format: :pdf, section: "Payments", preset: "all")

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert response.body.start_with?("%PDF")
    assert_match "activity-log-date-all-dates-section-payments.pdf", response.headers["Content-Disposition"]
    log = ActivityLog.order(:id).last
    assert_equal [ "Downloaded PDF", "Reports" ], [ log.action, log.section ]
    assert_equal "Downloaded Activity log (Date: All dates, Section: Payments)", log.detail
  end
end
