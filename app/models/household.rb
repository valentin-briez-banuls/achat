class Household < ApplicationRecord
  has_many :users, dependent: :nullify
  has_one :financial_profile, dependent: :destroy
  has_one :property_criterion, dependent: :destroy
  has_many :properties, dependent: :destroy

  validates :name, presence: true
  validate :maximum_two_users

  before_create :generate_invitation_token

  def full?
    users.count >= 2
  end

  def solo?
    users.count == 1
  end

  def partner_of(user)
    users.where.not(id: user.id).first
  end

  def total_monthly_income
    return 0 unless financial_profile

    financial_profile.salary_person_1 +
      financial_profile.salary_person_2 +
      financial_profile.other_income
  end

  private

  def maximum_two_users
    if users.size > 2
      errors.add(:base, "Un foyer ne peut pas contenir plus de 2 personnes")
    end
  end

  def generate_invitation_token
    self.invitation_token = SecureRandom.hex(20)
  end
end
