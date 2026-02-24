class CleanExpiredScrapeCachesJob < ApplicationJob
  queue_as :default

  def perform
    deleted_count = PropertyScrapeCache.cleanup_expired!
    Rails.logger.info("CleanExpiredScrapeCachesJob: Deleted #{deleted_count} expired cache entries")
  end
end

