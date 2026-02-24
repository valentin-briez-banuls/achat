class SimulationPolicy < ApplicationPolicy
  def owner?
    record.property.household == user.household
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:property).where(properties: { household_id: user.household_id })
    end
  end
end
