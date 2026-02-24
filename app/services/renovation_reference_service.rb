# Référentiel de coûts de rénovation en France (benchmarks sectoriels 2024)
# Sources : FNAIM, Batinfo, Artisans de France
class RenovationReferenceService
  BENCHMARKS = {
    cuisine:       { min: 5_000,  max: 20_000, unit: :forfait },
    salle_de_bain: { min: 3_000,  max: 12_000, unit: :forfait },
    sols:          { min: 25,     max: 80,     unit: :per_sqm },
    peinture:      { min: 10,     max: 30,     unit: :per_sqm },
    isolation:     { min: 20,     max: 60,     unit: :per_sqm },
    toiture:       { min: 80,     max: 200,    unit: :per_sqm },
    fenetres:      { min: 500,    max: 1_500,  unit: :forfait },
    electricite:   { min: 5_000,  max: 20_000, unit: :forfait },
    plomberie:     { min: 2_000,  max: 10_000, unit: :forfait },
    autre:         { min: 1_000,  max: 5_000,  unit: :forfait }
  }.freeze

  # Retourne les coûts estimés pour une catégorie donnée.
  # Pour les coûts au m², multiplie par la surface si fournie.
  def self.estimate(category, surface_sqm: nil)
    benchmark = BENCHMARKS[category.to_sym]
    return nil unless benchmark

    if benchmark[:unit] == :per_sqm && surface_sqm&.positive?
      {
        min: (benchmark[:min] * surface_sqm).round,
        max: (benchmark[:max] * surface_sqm).round,
        unit: :per_sqm,
        surface: surface_sqm
      }
    else
      {
        min: benchmark[:min],
        max: benchmark[:max],
        unit: benchmark[:unit]
      }
    end
  end

  def self.categories
    BENCHMARKS.keys
  end

  def self.benchmark_for(category)
    BENCHMARKS[category.to_sym]
  end
end
