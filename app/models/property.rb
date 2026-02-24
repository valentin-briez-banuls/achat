class Property < ApplicationRecord
  belongs_to :household
  has_one :property_score, dependent: :destroy
  has_many :simulations, dependent: :destroy
  has_many :visits, dependent: :destroy
  has_many :offers, dependent: :destroy
  has_many_attached :photos

  enum :property_type, { appartement: 0, maison: 1, terrain: 2, loft: 3, duplex: 4 }
  enum :condition, { ancien: 0, neuf: 1 }
  enum :status, {
    a_analyser: 0,
    a_visiter: 1,
    visite: 2,
    offre_faite: 3,
    refuse: 4,
    accepte: 5
  }

  ENERGY_CLASSES = %w[A B C D E F G].freeze

  validates :title, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :surface, presence: true, numericality: { greater_than: 0 }
  validates :city, presence: true
  validates :postal_code, format: { with: /\A\d{5}\z/ }, allow_blank: true
  validates :energy_class, inclusion: { in: ENERGY_CLASSES }, allow_nil: true, allow_blank: true
  validates :ges_class, inclusion: { in: ENERGY_CLASSES }, allow_nil: true, allow_blank: true
  validates :score_neighborhood, :score_view, :score_orientation,
            :score_renovation, :score_quietness, :score_brightness,
            numericality: { in: 1..5 }, allow_nil: true

  scope :by_score, -> { joins(:property_score).order("property_scores.total_score DESC") }
  scope :active, -> { where.not(status: [:refuse]) }
  scope :with_status, ->(status) { where(status: status) }

  def price_per_sqm
    return 0 if surface.zero?
    price / surface
  end

  def effective_price
    if agency_fees_included?
      price
    else
      price + (agency_fees || 0)
    end
  end

  def energy_class_rank
    ENERGY_CLASSES.index(energy_class) || 99
  end

  def recalculate_score!
    criteria = household.property_criterion
    return unless criteria

    PropertyMatcher.new(self, criteria).call
  end
end
