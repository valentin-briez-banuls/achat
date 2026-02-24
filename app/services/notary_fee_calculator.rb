# Calcul des frais de notaire
# Ancien : ~7-8% du prix (droits de mutation ~5.8% + émoluments + débours)
# Neuf : ~2-3% du prix (TVA déjà incluse, droits réduits)
class NotaryFeeCalculator
  # Barème des émoluments du notaire (tranches 2024)
  EMOLUMENT_BRACKETS = [
    { limit: 6_500, rate: 0.03870 },
    { limit: 17_000, rate: 0.01596 },
    { limit: 60_000, rate: 0.01064 },
    { limit: Float::INFINITY, rate: 0.00799 }
  ].freeze

  DROITS_MUTATION_ANCIEN = 0.0580  # ~5.80% (département + commune + état)
  DROITS_MUTATION_NEUF = 0.0071    # ~0.71% (taxe de publicité foncière réduite)
  CONTRIBUTION_SECURITE = 0.001    # 0.1% contribution de sécurité immobilière
  DEBOURS_FORFAIT = 1_200          # Forfait débours (documents, géomètre, etc.)

  attr_reader :price, :condition

  def initialize(price:, condition:)
    @price = price.to_d
    @condition = condition.to_s
  end

  def call
    {
      emoluments: emoluments,
      droits_mutation: droits_mutation,
      contribution_securite: contribution_securite,
      debours: DEBOURS_FORFAIT,
      total: total,
      percentage: percentage
    }
  end

  def total
    (emoluments + droits_mutation + contribution_securite + DEBOURS_FORFAIT).round(2)
  end

  def percentage
    return 0 if price.zero?
    (total / price * 100).round(2)
  end

  private

  def emoluments
    remaining = price
    total = BigDecimal("0")
    previous_limit = 0

    EMOLUMENT_BRACKETS.each do |bracket|
      bracket_amount = [remaining, bracket[:limit] - previous_limit].min
      total += bracket_amount * bracket[:rate]
      remaining -= bracket_amount
      previous_limit = bracket[:limit]
      break if remaining <= 0
    end

    # TVA sur émoluments (20%)
    (total * 1.20).round(2)
  end

  def droits_mutation
    rate = ancien? ? DROITS_MUTATION_ANCIEN : DROITS_MUTATION_NEUF
    (price * rate).round(2)
  end

  def contribution_securite
    (price * CONTRIBUTION_SECURITE).round(2)
  end

  def ancien?
    condition == "ancien"
  end
end
