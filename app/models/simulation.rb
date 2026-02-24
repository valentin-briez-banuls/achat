class Simulation < ApplicationRecord
  belongs_to :property

  enum :scenario, { standard: 0, optimiste: 1, pessimiste: 2 }

  validates :loan_rate, numericality: { greater_than: 0, less_than: 15 }
  validates :loan_duration_years, inclusion: { in: [10, 15, 20, 25, 30] }
  validates :personal_contribution, numericality: { greater_than_or_equal_to: 0 }

  def household
    property.household
  end

  def financial_profile
    household.financial_profile
  end

  def recalculate!
    PropertyFinanceSimulator.new(self).call
  end

  def danger_level
    return :critical if debt_ratio && debt_ratio > 35
    return :warning if debt_ratio && debt_ratio > 30
    :safe
  end

  def danger_label
    case danger_level
    when :critical then "Danger financier"
    when :warning then "Attention"
    when :safe then "OK"
    end
  end
end
