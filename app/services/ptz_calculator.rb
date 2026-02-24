# Calcul du Prêt à Taux Zéro (PTZ) - Barème 2025/2026
# Sources : economie.gouv.fr, CAFPI, pretatauxzeroplus.com
class PTZCalculator
  # Plafonds de ressources (revenu fiscal de référence N-2) par zone et nombre de personnes
  INCOME_LIMITS = {
    "Abis" => [49_000, 73_500, 88_200, 102_900, 117_600, 132_300, 147_000, 161_700],
    "A"    => [49_000, 73_500, 88_200, 102_900, 117_600, 132_300, 147_000, 161_700],
    "B1"   => [34_500, 51_750, 62_100, 72_450, 82_800, 93_150, 103_500, 113_850],
    "B2"   => [31_500, 47_250, 56_700, 66_150, 75_600, 85_050, 94_500, 103_950],
    "C"    => [28_500, 42_750, 51_300, 59_850, 68_400, 76_950, 85_500, 94_050]
  }.freeze

  # Plafonds du coût de l'opération par zone et nombre de personnes
  OPERATION_LIMITS = {
    "Abis" => [150_000, 225_000, 270_000, 315_000, 360_000],
    "A"    => [150_000, 225_000, 270_000, 315_000, 360_000],
    "B1"   => [135_000, 202_500, 243_000, 283_500, 324_000],
    "B2"   => [110_000, 165_000, 198_000, 231_000, 264_000],
    "C"    => [100_000, 150_000, 180_000, 210_000, 240_000]
  }.freeze

  # Quotités de financement selon le type et la zone
  QUOTITES = {
    neuf_collectif: { "Abis" => 50, "A" => 50, "B1" => 50, "B2" => 50, "C" => 50 },
    neuf_individuel: { "Abis" => 30, "A" => 30, "B1" => 30, "B2" => 30, "C" => 30 },
    ancien_travaux: { "Abis" => 0, "A" => 0, "B1" => 0, "B2" => 50, "C" => 50 },
    hlm: { "Abis" => 20, "A" => 20, "B1" => 20, "B2" => 20, "C" => 20 }
  }.freeze

  # Durées de remboursement et différé selon la tranche de revenus
  # Tranche 1 = revenus les plus bas, Tranche 3 = revenus les plus hauts
  REPAYMENT_TERMS = {
    1 => { total_years: 25, deferred_years: 10, repayment_years: 15 },
    2 => { total_years: 22, deferred_years: 8, repayment_years: 14 },
    3 => { total_years: 20, deferred_years: 2, repayment_years: 18 }
  }.freeze

  attr_reader :zone, :household_size, :fiscal_income, :property_type,
              :operation_cost, :condition

  def initialize(zone:, household_size:, fiscal_income:, property_type:, operation_cost:, condition:)
    @zone = zone.to_s
    @household_size = [household_size, 1].max
    @fiscal_income = fiscal_income.to_d
    @property_type = property_type.to_sym
    @operation_cost = operation_cost.to_d
    @condition = condition.to_s
  end

  def call
    {
      eligible: eligible?,
      reason: ineligibility_reason,
      max_amount: eligible? ? max_amount : 0,
      quotite: quotite_percent,
      income_tranche: income_tranche,
      repayment_terms: eligible? ? repayment_terms : nil,
      monthly_payment: eligible? ? monthly_payment_after_deferred : 0,
      operation_limit: operation_limit
    }
  end

  def eligible?
    valid_zone? && within_income_limits? && quotite_percent > 0
  end

  def max_amount
    return BigDecimal("0") unless eligible?
    base = [operation_cost, operation_limit].min
    (base * quotite_percent / 100).round(2)
  end

  private

  def ineligibility_reason
    return nil if eligible?
    return "Zone PTZ invalide" unless valid_zone?
    return "Revenus supérieurs au plafond" unless within_income_limits?
    return "Type de bien non éligible dans cette zone" if quotite_percent.zero?
    "Non éligible"
  end

  def valid_zone?
    INCOME_LIMITS.key?(zone)
  end

  def within_income_limits?
    return false unless valid_zone?
    fiscal_income <= income_limit
  end

  def income_limit
    index = [household_size - 1, 7].min
    INCOME_LIMITS[zone][index]
  end

  def operation_limit
    return 0 unless valid_zone?
    index = [household_size - 1, 4].min
    OPERATION_LIMITS[zone][index].to_d
  end

  def quotite_percent
    type_key = determine_type_key
    return 0 unless QUOTITES.key?(type_key)
    QUOTITES[type_key][zone] || 0
  end

  def determine_type_key
    case condition
    when "neuf"
      property_type == :maison ? :neuf_individuel : :neuf_collectif
    when "ancien"
      :ancien_travaux
    else
      :neuf_collectif
    end
  end

  def income_tranche
    return 3 unless valid_zone?
    ratio = fiscal_income.to_f / income_limit.to_f
    if ratio <= 0.5
      1
    elsif ratio <= 0.8
      2
    else
      3
    end
  end

  def repayment_terms
    REPAYMENT_TERMS[income_tranche]
  end

  def monthly_payment_after_deferred
    return BigDecimal("0") unless eligible?
    terms = repayment_terms
    # PTZ = pas d'intérêts, remboursement du capital uniquement après le différé
    (max_amount / (terms[:repayment_years] * 12)).round(2)
  end
end
