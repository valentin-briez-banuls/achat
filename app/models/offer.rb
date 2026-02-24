class Offer < ApplicationRecord
  belongs_to :property

  enum :status, { en_attente: 0, acceptee: 1, refusee: 2, contre_offre: 3, expiree: 4 }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :offered_on, presence: true

  scope :pending, -> { en_attente }
  scope :recent, -> { order(offered_on: :desc) }

  def discount_percent
    return 0 unless property&.price&.positive?
    ((property.price - amount) / property.price * 100).round(1)
  end
end
