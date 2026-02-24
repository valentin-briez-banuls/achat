class Visit < ApplicationRecord
  belongs_to :property
  belongs_to :user

  enum :status, { planifiee: 0, effectuee: 1, annulee: 2 }
  enum :verdict, { negatif: 0, neutre: 1, positif: 2, coup_de_coeur: 3 }, prefix: true

  validates :scheduled_at, presence: true

  scope :upcoming, -> { planifiee.where("scheduled_at >= ?", Time.current).order(:scheduled_at) }
  scope :past, -> { effectuee.order(scheduled_at: :desc) }
end
