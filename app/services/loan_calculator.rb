# Calcul de prêt immobilier - Formule d'amortissement classique
# Mensualité = [C × t/12] / [1 - (1 + t/12)^(-n×12)]
# C = capital emprunté, t = taux annuel, n = durée en années
class LoanCalculator
  attr_reader :principal, :annual_rate, :duration_years

  def initialize(principal:, annual_rate:, duration_years:)
    @principal = principal.to_d
    @annual_rate = annual_rate.to_d
    @duration_years = duration_years
  end

  def call
    {
      monthly_payment: monthly_payment,
      total_cost: total_cost,
      total_interest: total_interest,
      amortization_schedule: amortization_schedule
    }
  end

  def monthly_payment
    return BigDecimal("0") if principal.zero? || annual_rate.zero?

    monthly_rate = annual_rate / 100 / 12
    num_payments = duration_years * 12

    numerator = principal * monthly_rate
    denominator = 1 - (1 + monthly_rate)**(-num_payments)

    (numerator / denominator).round(2)
  end

  def total_cost
    monthly_payment * duration_years * 12
  end

  def total_interest
    total_cost - principal
  end

  # Simule l'impact d'une variation de taux
  def self.rate_impact(principal:, duration_years:, base_rate:, variations: [-0.5, -0.25, 0, 0.25, 0.5, 1.0])
    variations.map do |delta|
      rate = base_rate + delta
      next if rate <= 0
      calc = new(principal: principal, annual_rate: rate, duration_years: duration_years)
      { rate: rate, monthly_payment: calc.monthly_payment, total_cost: calc.total_cost }
    end.compact
  end

  private

  def amortization_schedule
    return [] if principal.zero? || annual_rate.zero?

    monthly_rate = annual_rate / 100 / 12
    balance = principal
    schedule = []

    (duration_years * 12).times do |month|
      interest = (balance * monthly_rate).round(2)
      principal_part = monthly_payment - interest
      balance -= principal_part

      schedule << {
        month: month + 1,
        payment: monthly_payment,
        principal: principal_part.round(2),
        interest: interest,
        balance: [balance, 0].max.round(2)
      }
    end

    schedule
  end
end
