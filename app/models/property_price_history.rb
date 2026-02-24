class PropertyPriceHistory < ApplicationRecord
  belongs_to :property

  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :scraped_at, presence: true
  validates :source, presence: true, inclusion: { in: %w[scraper manual] }
end
