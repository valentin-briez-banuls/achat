class PropertyPolicy < ApplicationPolicy
  def import_from_url?
    create?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(household: user.household)
    end
  end
end
