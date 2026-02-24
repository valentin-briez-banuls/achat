class PropertyCriterion < ApplicationRecord
  belongs_to :household

  enum :property_condition, { any_condition: 0, ancien: 1, neuf: 2 }

  ENERGY_CLASSES = %w[A B C D E F G].freeze

  validates :max_budget, numericality: { greater_than: 0 }, allow_nil: true
  validates :min_surface, numericality: { greater_than: 0 }, allow_nil: true
  validates :min_bedrooms, numericality: { greater_than_or_equal_to: 0 }
  validates :max_work_distance_km, numericality: { greater_than: 0 }, allow_nil: true
  validates :min_energy_class, inclusion: { in: ENERGY_CLASSES }, allow_nil: true

  validates :weight_neighborhood, :weight_view, :weight_orientation,
            :weight_renovation, :weight_quietness, :weight_brightness,
            numericality: { in: 0..10 }

  def total_weight
    weight_neighborhood + weight_view + weight_orientation +
      weight_renovation + weight_quietness + weight_brightness
  end

  def weight_for(criterion)
    send(:"weight_#{criterion}")
  end
end
