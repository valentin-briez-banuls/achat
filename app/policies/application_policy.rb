class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    true
  end

  def show?
    owner?
  end

  def create?
    owner?
  end

  def new?
    create?
  end

  def update?
    owner?
  end

  def edit?
    update?
  end

  def destroy?
    owner?
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.where(household: user.household)
    end

    private

    attr_reader :user, :scope
  end

  private

  def owner?
    record.respond_to?(:household) && record.household == user.household
  end
end
