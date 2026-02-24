# Calcul du profil financier du ménage
# Capacité d'emprunt, taux d'endettement, mensualité max, reste à vivre
class FinancialProfileCalculator
  MAX_DEBT_RATIO = 35.0  # Taux d'endettement max recommandé (HCSF)
  MIN_REMAINING_TO_LIVE_SOLO = 700    # Minimum reste à vivre solo
  MIN_REMAINING_TO_LIVE_COUPLE = 1000 # Minimum reste à vivre couple
  INSURANCE_RATE = 0.0034  # Taux assurance emprunteur moyen (0.34%)

  attr_reader :profile

  def initialize(profile)
    @profile = profile
  end

  def call
    {
      borrowing_capacity: borrowing_capacity,
      debt_ratio: current_debt_ratio,
      max_monthly_payment: max_monthly_payment,
      remaining_to_live: remaining_to_live,
      optimal_budget: optimal_budget,
      danger_indicators: danger_indicators
    }
  end

  # Mensualité maximale = 35% des revenus nets
  def max_monthly_payment
    (total_income * MAX_DEBT_RATIO / 100).round(2)
  end

  # Capacité d'emprunt = montant max empruntable avec la mensualité max
  # En inversant la formule d'amortissement :
  # C = M × [1 - (1 + t/12)^(-n×12)] / (t/12)
  def borrowing_capacity
    return BigDecimal("0") unless rate_available?

    monthly_rate = effective_monthly_rate
    num_payments = profile.desired_duration_years * 12
    max_payment = max_monthly_payment - monthly_insurance

    return BigDecimal("0") if max_payment <= 0

    capacity = max_payment * (1 - (1 + monthly_rate)**(-num_payments)) / monthly_rate
    capacity.round(2)
  end

  # Budget optimal = capacité d'emprunt + apport - frais de notaire estimés
  def optimal_budget
    raw = borrowing_capacity + profile.personal_contribution
    # On estime ~8% de frais de notaire pour l'ancien
    (raw / 1.08).round(2)
  end

  # Taux d'endettement actuel (avec les charges existantes)
  def current_debt_ratio
    return BigDecimal("0") if total_income.zero?
    (profile.monthly_charges / total_income * 100).round(2)
  end

  # Reste à vivre = revenus - mensualité max - charges fixes
  def remaining_to_live
    (total_income - max_monthly_payment - profile.monthly_charges).round(2)
  end

  def danger_indicators
    indicators = []

    if current_debt_ratio > 20
      indicators << { level: :warning, message: "Charges existantes déjà élevées (#{current_debt_ratio}%)" }
    end

    if remaining_to_live < min_remaining_to_live
      indicators << { level: :critical, message: "Reste à vivre insuffisant (#{remaining_to_live}€)" }
    end

    if profile.remaining_savings < 5000
      indicators << { level: :warning, message: "Épargne de sécurité faible après apport" }
    end

    unless stable_employment?
      indicators << { level: :info, message: "Contrat non-CDI : financement potentiellement plus difficile" }
    end

    indicators
  end

  private

  def total_income
    profile.total_monthly_income
  end

  def rate_available?
    profile.proposed_rate.present? && profile.proposed_rate > 0
  end

  def effective_monthly_rate
    profile.proposed_rate / 100 / 12
  end

  def monthly_insurance
    # Assurance sur le capital emprunté estimé
    estimated_capital = max_monthly_payment * profile.desired_duration_years * 12 * 0.6
    (estimated_capital * INSURANCE_RATE / 12).round(2)
  end

  def min_remaining_to_live
    profile.household.solo? ? MIN_REMAINING_TO_LIVE_SOLO : MIN_REMAINING_TO_LIVE_COUPLE
  end

  def stable_employment?
    profile.p1_cdi_1? || profile.p1_fonctionnaire_1?
  end
end
