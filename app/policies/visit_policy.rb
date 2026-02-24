class VisitPolicy < ApplicationPolicy
  def owner?
    record.property.household == user.household
  end
end
