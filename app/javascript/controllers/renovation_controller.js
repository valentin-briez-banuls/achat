import { Controller } from "@hotwired/stimulus"

const BENCHMARKS = {
  cuisine:       { min: 5000,  max: 20000, unit: "forfait" },
  salle_de_bain: { min: 3000,  max: 12000, unit: "forfait" },
  sols:          { min: 25,    max: 80,    unit: "per_sqm" },
  peinture:      { min: 10,    max: 30,    unit: "per_sqm" },
  isolation:     { min: 20,    max: 60,    unit: "per_sqm" },
  toiture:       { min: 80,    max: 200,   unit: "per_sqm" },
  fenetres:      { min: 500,   max: 1500,  unit: "forfait" },
  electricite:   { min: 5000,  max: 20000, unit: "forfait" },
  plomberie:     { min: 2000,  max: 10000, unit: "forfait" },
  autre:         { min: 1000,  max: 5000,  unit: "forfait" }
}

export default class extends Controller {
  static targets = ["category", "costMin", "costMax", "hint", "energyNote",
                    "renovationBudgetField", "renovationBudgetIncluded"]
  static values = { surface: Number }

  categoryChanged() {
    const category = this.categoryTarget.value
    const benchmark = BENCHMARKS[category]

    if (!benchmark) return

    const surface = this.surfaceValue > 0 ? this.surfaceValue : 50
    let min = benchmark.min
    let max = benchmark.max

    if (benchmark.unit === "per_sqm") {
      min = Math.round(benchmark.min * surface)
      max = Math.round(benchmark.max * surface)
    }

    if (this.hasCostMinTarget) this.costMinTarget.value = min
    if (this.hasCostMaxTarget) this.costMaxTarget.value = max

    if (this.hasHintTarget) {
      const hint = benchmark.unit === "per_sqm"
        ? `Estimation basée sur ${surface} m² à ${benchmark.min}–${benchmark.max} €/m²`
        : `Forfait estimé : ${min.toLocaleString("fr-FR")} – ${max.toLocaleString("fr-FR")} €`
      this.hintTarget.textContent = hint
      this.hintTarget.classList.remove("hidden")
    }

    if (this.hasEnergyNoteTarget) {
      if (category === "isolation" || category === "fenetres") {
        this.energyNoteTarget.classList.remove("hidden")
      } else {
        this.energyNoteTarget.classList.add("hidden")
      }
    }
  }

  toggleBudgetField() {
    if (!this.hasRenovationBudgetFieldTarget) return
    if (this.renovationBudgetIncludedTarget.checked) {
      this.renovationBudgetFieldTarget.classList.remove("hidden")
    } else {
      this.renovationBudgetFieldTarget.classList.add("hidden")
    }
  }
}
