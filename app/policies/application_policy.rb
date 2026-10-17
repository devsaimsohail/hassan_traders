class ApplicationPolicy
  attr_reader :access, :record

  def initialize(access, record)
    @access = access
    @record = record
  end

  private
    def can?(permission)
      access.present? && access.can?(permission)
    end

    def sees?(permission)
      access.present? && access.sees?(permission)
    end
end
