class HomeController < ApplicationController
  def show
    @permissions = RolePermission::PERMISSIONS.map { |key, label| [ label, Current.access.level(key) ] }
  end
end
