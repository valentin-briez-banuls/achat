class PropertyScrapeCache < ApplicationRecord
  validates :url_hash, presence: true, uniqueness: true
  validates :scraped_data, presence: true

  scope :active, -> { where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }

  # Durée de validité du cache (7 jours par défaut)
  CACHE_DURATION = 7.days

  # Trouver un cache valide pour une URL
  def self.find_by_url(url)
    hash = Digest::SHA256.hexdigest(url)
    active.find_by(url_hash: hash)
  end

  # Créer ou mettre à jour un cache pour une URL
  def self.cache_for_url(url, data, images = [])
    hash = Digest::SHA256.hexdigest(url)
    cache = find_or_initialize_by(url_hash: hash)
    cache.scraped_data = data
    cache.images_urls = images
    cache.expires_at = CACHE_DURATION.from_now
    cache.save!
    cache
  end

  # Nettoyer les caches expirés
  def self.cleanup_expired!
    expired.delete_all
  end

  def expired?
    expires_at <= Time.current
  end
end

