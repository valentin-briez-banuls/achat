class FinancialProfile < ApplicationRecord
  belongs_to :household

  enum :contract_type_person_1, { cdi_1: 0, cdd_1: 1, freelance_1: 2, fonctionnaire_1: 3 }, prefix: :p1
  enum :contract_type_person_2, { cdi_2: 0, cdd_2: 1, freelance_2: 2, fonctionnaire_2: 3, none_2: 4 }, prefix: :p2

  validates :salary_person_1, numericality: { greater_than_or_equal_to: 0 }
  validates :salary_person_2, numericality: { greater_than_or_equal_to: 0 }
  validates :other_income, numericality: { greater_than_or_equal_to: 0 }
  validates :monthly_charges, numericality: { greater_than_or_equal_to: 0 }
  validates :existing_loan_payments, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :other_monthly_charges, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :personal_contribution, numericality: { greater_than_or_equal_to: 0 }
  validates :remaining_savings, numericality: { greater_than_or_equal_to: 0 }
  validates :proposed_rate, numericality: { greater_than: 0, less_than: 15 }, allow_nil: true
  validates :desired_duration_years, inclusion: { in: [10, 15, 20, 25, 30] }
  validates :household_size, numericality: { greater_than: 0, less_than_or_equal_to: 10 }
  validates :ptz_zone, inclusion: { in: %w[A Abis B1 B2 C] }, allow_nil: true

  PTZ_ZONES = %w[A Abis B1 B2 C].freeze
  DURATIONS = [10, 15, 20, 25, 30].freeze

  # Crédits en cours uniquement (règle HCSF pour le taux d'endettement)
  def loan_payments_for_debt_ratio
    existing_loan_payments || 0
  end

  # Total de toutes les charges (pour le reste à vivre)
  def total_charges
    (existing_loan_payments || 0) + (other_monthly_charges || 0)
  end

  def total_monthly_income
    salary_person_1 + salary_person_2 + other_income
  end

  def total_annual_income
    total_monthly_income * 12
  end

  def recalculate!
    result = FinancialProfileCalculator.new(self).call
    update!(
      borrowing_capacity: result[:borrowing_capacity],
      debt_ratio: result[:debt_ratio],
      max_monthly_payment: result[:max_monthly_payment],
      remaining_to_live: result[:remaining_to_live]
    )
  end
end
