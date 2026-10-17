class PeopleController < ApplicationController
  before_action :set_person, only: %i[ disable enable unlock ]

  def new
    authorize User.new, :create?, policy_class: PersonPolicy
    @person = User.new
    @role = "accountant"
  end

  def create
    authorize User.new, :create?, policy_class: PersonPolicy
    @role = params.dig(:person, :role).to_s
    @person = User.find_by(mobile: User.normalize_mobile(person_params[:mobile])) || User.new(person_params.merge(must_change_password: true))

    if !Company::ROLES.key?(@role)
      @person.errors.add(:base, "Please choose a role")
    elsif @person.persisted? && @person.role_in(Current.company)
      @person.errors.add(:base, "#{@person.name} is already in #{Current.company.name}")
    end

    if @person.errors.none? && save_person
      redirect_to settings_path, notice: "#{@person.name} is added as #{Company::ROLES[@role]} and can log in now."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def disable
    @person.transaction do
      @person.update!(disabled_at: Time.current, disabled_by: Current.user)
      @person.forget_me!
      ActivityLog.record!(action: "Edited", section: "Users", detail: "Disabled login for #{@person.name}")
    end
    redirect_to settings_path, notice: "#{@person.name} is logged out and can no longer log in."
  end

  def enable
    @person.update!(disabled_at: nil, disabled_by: nil)
    ActivityLog.record!(action: "Edited", section: "Users", detail: "Enabled login for #{@person.name}")
    redirect_to settings_path, notice: "#{@person.name} can log in again."
  end

  def unlock
    @person.unlock_access!
    ActivityLog.record!(action: "Edited", section: "Users", detail: "Unlocked login for #{@person.name}")
    redirect_to settings_path, notice: "#{@person.name} can try logging in again."
  end

  private
    def set_person
      @person = Current.company.people.find(params[:id])
      authorize @person, policy_class: PersonPolicy
    end

    def person_params
      params.require(:person).permit(:name, :mobile, :email, :city, :password)
    end

    def save_person
      ActiveRecord::Base.transaction do
        @person.save! if @person.new_record?
        @person.assign_role!(@role, Current.company)
        ActivityLog.record!(action: "Created", section: "Users", detail: "Added #{@person.name} as #{Company::ROLES[@role]}")
      end
      true
    rescue ActiveRecord::RecordInvalid
      false
    end
end
