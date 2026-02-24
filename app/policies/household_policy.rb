class HouseholdPolicy < ApplicationPolicy
  def show?
    record == user.household
  end

  def update?
    record == user.household
  end
end
