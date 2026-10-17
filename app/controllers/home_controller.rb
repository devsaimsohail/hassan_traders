class HomeController < ApplicationController
  def show
    unless policy(:dashboard).show?
      first = helpers.nav_groups.flat_map(&:last).find { |item| item[:permission] }
      return first ? redirect_to(send(first[:path])) : render(:no_access)
    end

    @dashboard = Dashboard.new(Current.company)
    @activity = Current.company.activity_logs.order(created_at: :desc, id: :desc).limit(5)
  end
end
