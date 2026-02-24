class RenovationItem < ApplicationRecord
  belongs_to :property

  enum :category, {
    cuisine: 0,
    salle_de_bain: 1,
    sols: 2,
    peinture: 3,
    isolation: 4,
    toiture: 5,
    fenetres: 6,
    electricite: 7,
    plomberie: 8,
    autre: 9
  }

  CATEGORY_LABELS = {
    cuisine: "Cuisine",
    salle_de_bain: "Salle de bain",
    sols: "Sols",
    peinture: "Peinture",
    isolation: "Isolation",
    toiture: "Toiture",
    fenetres: "Fenêtres",
    electricite: "Électricité",
    plomberie: "Plomberie",
    autre: "Autre"
  }.freeze

  ENERGY_UPGRADE_CATEGORIES = %w[isolation fenetres].freeze

  validates :category, presence: true
  validates :estimated_cost_min, numericality: { greater_than_or_equal_to: 0 }
  validates :estimated_cost_max, numericality: { greater_than_or_equal_to: 0 }
  validate :max_not_less_than_min

  def household
    property.household
  end

  def category_label
    CATEGORY_LABELS[category.to_sym] || category.humanize
  end

  def energy_upgrade?
    ENERGY_UPGRADE_CATEGORIES.include?(category.to_s)
  end

  private

  def max_not_less_than_min
    return unless estimated_cost_min && estimated_cost_max
    if estimated_cost_max < estimated_cost_min
      errors.add(:estimated_cost_max, "doit être supérieur ou égal au coût minimum")
    end
  end
end
