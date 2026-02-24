class PropertyPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(household: user.household)
    end
  end
end
