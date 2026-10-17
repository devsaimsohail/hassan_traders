module SessionTestHelper
  def sign_in_as(user, company = user.companies.first)
    sign_in user
    post company_selection_path, params: { company_id: company.id }
  end

  def last_log
    ActivityLog.order(:id).last
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include Devise::Test::IntegrationHelpers
  include SessionTestHelper
end
