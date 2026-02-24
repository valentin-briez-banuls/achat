class DownloadPropertyImagesJob < ApplicationJob
  queue_as :default

  def perform(property_id)
    property = Property.find_by(id: property_id)
    return unless property

    image_urls = property.parsed_image_urls
    return if image_urls.empty?

    Rails.logger.info("DownloadPropertyImagesJob: Downloading #{image_urls.size} images for property ##{property_id}")

    extractor = PropertyImageExtractorService.new("", "")
    extractor.download_and_attach_to(property, image_urls)

    # Vider image_urls une fois les images téléchargées pour éviter les problèmes CORS
    property.update_column(:image_urls, nil)

    Rails.logger.info("DownloadPropertyImagesJob: Done. #{property.photos.count} photos attached.")
  rescue => e
    Rails.logger.error("DownloadPropertyImagesJob: Error for property ##{property_id}: #{e.message}")
    raise
  end
end


