class ApplicationPolicy
  attr_reader :access, :record

  def initialize(access, record)
    @access = access
    @record = record
  end

  def index? = false
  def show? = false
  def create? = false
  def new? = create?
  def update? = false
  def edit? = update?
  def destroy? = false

  private
    def can?(permission)
      access.present? && access.can?(permission)
    end

    def sees?(permission)
      access.present? && access.sees?(permission)
    end
end
