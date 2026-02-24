# Scoring automatique d'un bien par rapport aux critères du ménage
# Score /100 avec correspondance stricte, partielle ou non compatible
class PropertyMatcher
  MANDATORY_CRITERIA_WEIGHT = 60  # 60% du score pour les critères obligatoires
  WEIGHTED_CRITERIA_WEIGHT = 40   # 40% du score pour les critères pondérés

  attr_reader :property, :criteria

  def initialize(property, criteria)
    @property = property
    @criteria = criteria
  end

  def call
    scores = calculate_all_scores
    total = compute_total(scores)
    compatibility = determine_compatibility(scores)

    score = property.property_score || property.build_property_score
    score.update!(
      total_score: total,
      compatibility: compatibility,
      budget_score: scores[:budget],
      surface_score: scores[:surface],
      bedrooms_score: scores[:bedrooms],
      outdoor_score: scores[:outdoor],
      parking_score: scores[:parking],
      energy_score: scores[:energy],
      location_score: scores[:location],
      neighborhood_score: scores[:neighborhood],
      view_score: scores[:view],
      orientation_score: scores[:orientation],
      renovation_score: scores[:renovation],
      quietness_score: scores[:quietness],
      brightness_score: scores[:brightness],
      details: build_details(scores)
    )

    score
  end

  private

  def calculate_all_scores
    {
      # Critères obligatoires (0 ou max)
      budget: score_budget,
      surface: score_surface,
      bedrooms: score_bedrooms,
      outdoor: score_outdoor,
      parking: score_parking,
      energy: score_energy,
      location: score_location,
      # Critères pondérés (1-5 × poids)
      neighborhood: score_weighted(:neighborhood),
      view: score_weighted(:view),
      orientation: score_weighted(:orientation),
      renovation: score_weighted(:renovation),
      quietness: score_weighted(:quietness),
      brightness: score_weighted(:brightness)
    }
  end

  # Budget : 100% si dans le budget, dégradé progressif jusqu'à +20%
  def score_budget
    return 100 unless criteria.max_budget&.positive?
    ratio = property.effective_price / criteria.max_budget
    if ratio <= 1.0
      100
    elsif ratio <= 1.05
      80
    elsif ratio <= 1.10
      50
    elsif ratio <= 1.20
      20
    else
      0
    end
  end

  def score_surface
    return 100 unless criteria.min_surface&.positive?
    ratio = property.surface / criteria.min_surface
    if ratio >= 1.0
      100
    elsif ratio >= 0.90
      60
    elsif ratio >= 0.80
      30
    else
      0
    end
  end

  def score_bedrooms
    return 100 unless criteria.min_bedrooms&.positive?
    return 100 unless property.bedrooms
    diff = property.bedrooms - criteria.min_bedrooms
    if diff >= 0
      100
    elsif diff == -1
      40
    else
      0
    end
  end

  def score_outdoor
    return 100 unless criteria.outdoor_required?
    property.has_outdoor? ? 100 : 0
  end

  def score_parking
    return 100 unless criteria.parking_required?
    property.has_parking? ? 100 : 0
  end

  def score_energy
    return 100 unless criteria.min_energy_class.present?
    return 50 unless property.energy_class.present?

    classes = PropertyCriterion::ENERGY_CLASSES
    property_rank = classes.index(property.energy_class) || 99
    criteria_rank = classes.index(criteria.min_energy_class) || 99

    if property_rank <= criteria_rank
      100
    elsif property_rank == criteria_rank + 1
      50
    else
      0
    end
  end

  def score_location
    return 100 unless criteria.geographic_zone.present?
    return 100 if criteria.geographic_zone.downcase.include?(property.city.downcase)
    return 50 if criteria.geographic_zone.downcase.include?(property.postal_code[0..1])
    0
  end

  # Critères pondérés : le score utilisateur (1-5) normalisé sur 100
  def score_weighted(criterion)
    user_score = property.send(:"score_#{criterion}")
    return 50 unless user_score # Défaut neutre si pas évalué
    (user_score / 5.0 * 100).round
  end

  def compute_total(scores)
    mandatory_scores = [:budget, :surface, :bedrooms, :outdoor, :parking, :energy, :location]
    weighted_scores = [:neighborhood, :view, :orientation, :renovation, :quietness, :brightness]

    # Moyenne pondérée des critères obligatoires
    mandatory_avg = mandatory_scores.sum { |s| scores[s] } / mandatory_scores.size.to_f

    # Moyenne pondérée des critères subjectifs avec poids personnalisés
    total_weight = criteria.total_weight
    if total_weight > 0
      weighted_avg = weighted_scores.sum { |s| scores[s] * criteria.weight_for(s) } / total_weight.to_f
    else
      weighted_avg = 50
    end

    total = (mandatory_avg * MANDATORY_CRITERIA_WEIGHT / 100.0) +
            (weighted_avg * WEIGHTED_CRITERIA_WEIGHT / 100.0)

    total.round
  end

  def determine_compatibility(scores)
    mandatory_scores = [:budget, :surface, :bedrooms, :outdoor, :parking]
    all_mandatory_pass = mandatory_scores.all? { |s| scores[s] >= 80 }
    any_mandatory_fail = mandatory_scores.any? { |s| scores[s] == 0 }

    if all_mandatory_pass
      :stricte
    elsif any_mandatory_fail
      :non_compatible
    else
      :partielle
    end
  end

  def build_details(scores)
    scores.transform_values { |v| v }
  end
end
