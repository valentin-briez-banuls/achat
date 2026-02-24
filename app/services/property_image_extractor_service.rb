require "down"

class PropertyImageExtractorService
  attr_reader :errors

  MAX_IMAGES = 10

  def initialize(html, url)
    @html = html
    @url = url
    @errors = []
  end

  def call
    image_urls = extract_image_urls
    return [] if image_urls.empty?

    Rails.logger.info("PropertyImageExtractorService: Found #{image_urls.size} images")
    image_urls.take(MAX_IMAGES)
  rescue StandardError => e
    @errors << "Erreur lors de l'extraction des images : #{e.message}"
    Rails.logger.error("PropertyImageExtractorService error: #{e.message}\n#{e.backtrace.join("\n")}")
    []
  end

  def download_and_attach_to(property, image_urls)
    return if image_urls.blank?

    Rails.logger.info("PropertyImageExtractorService: Downloading #{image_urls.size} images")

    image_urls.each_with_index do |image_url, index|
      begin
        # Télécharger l'image
        tempfile = Down.download(image_url, max_size: 10.megabytes)

        # Déterminer le nom du fichier
        filename = "photo_#{index + 1}#{File.extname(tempfile.original_filename || ".jpg")}"

        # Attacher au bien
        property.photos.attach(
          io: tempfile,
          filename: filename,
          content_type: tempfile.content_type
        )

        Rails.logger.info("PropertyImageExtractorService: Downloaded image #{index + 1}/#{image_urls.size}")
      rescue StandardError => e
        Rails.logger.error("PropertyImageExtractorService: Failed to download #{image_url}: #{e.message}")
        @errors << "Échec du téléchargement de l'image #{index + 1}"
      ensure
        tempfile&.close
      end
    end

    Rails.logger.info("PropertyImageExtractorService: Successfully attached #{property.photos.count} images")
  end

  private

  def extract_image_urls
    urls = []

    # 1. Extraire depuis JSON-LD
    json_ld = extract_json_ld(@html)
    if json_ld
      urls.concat(extract_from_json_ld(json_ld))
    end

    # 2. Extraire depuis les meta tags Open Graph
    urls.concat(extract_from_meta_tags)

    # 3. Extraire depuis les éléments img avec des classes spécifiques
    urls.concat(extract_from_img_tags)

    # Nettoyer et dédupliquer les URLs
    urls = urls.map { |url| normalize_url(url) }
                .compact
                .uniq
                .select { |url| valid_image_url?(url) }

    urls
  end

  def extract_json_ld(html)
    if html =~ /<script[^>]*type=["']application\/ld\+json["'][^>]*>(.*?)<\/script>/mi
      JSON.parse($1) rescue nil
    end
  end

  def extract_from_json_ld(json_ld)
    urls = []

    # Image unique
    if json_ld["image"].is_a?(String)
      urls << json_ld["image"]
    elsif json_ld["image"].is_a?(Array)
      urls.concat(json_ld["image"])
    elsif json_ld["image"].is_a?(Hash) && json_ld["image"]["url"]
      urls << json_ld["image"]["url"]
    end

    # Photos multiples
    if json_ld["photo"].is_a?(Array)
      urls.concat(json_ld["photo"])
    end

    urls
  end

  def extract_from_meta_tags
    urls = []

    # Open Graph images
    @html.scan(/<meta[^>]*property=["']og:image["'][^>]*content=["']([^"']+)["']/i) do |match|
      urls << match[0]
    end

    @html.scan(/<meta[^>]*content=["']([^"']+)["'][^>]*property=["']og:image["']/i) do |match|
      urls << match[0]
    end

    urls
  end

  def extract_from_img_tags
    urls = []

    # Images avec des classes spécifiques aux annonces immobilières
    patterns = [
      /<img[^>]*class=["'][^"']*(?:property|gallery|photo|slide|carousel)[^"']*["'][^>]*src=["']([^"']+)["']/i,
      /<img[^>]*src=["']([^"']+)["'][^>]*class=["'][^"']*(?:property|gallery|photo|slide|carousel)[^"']*["']/i,
      /<img[^>]*data-src=["']([^"']+)["'][^>]*class=["'][^"']*(?:property|gallery|photo|slide)[^"']*["']/i
    ]

    patterns.each do |pattern|
      @html.scan(pattern) do |match|
        urls << match[0]
      end
    end

    urls
  end

  def normalize_url(url)
    return nil if url.blank?

    # Supprimer les espaces
    url = url.strip

    # Si l'URL est relative, la convertir en absolue
    if url.start_with?("/")
      uri = URI.parse(@url)
      url = "#{uri.scheme}://#{uri.host}#{url}"
    elsif !url.match?(/^https?:\/\//)
      return nil
    end

    url
  rescue StandardError
    nil
  end

  def valid_image_url?(url)
    return false if url.blank?
    return false if url.length > 2000 # URLs trop longues sont suspectes
    return false if url.include?("data:image") # Ignorer les data URIs
    return false if url.match?(/\.(svg|gif)$/i) # Ignorer SVG et GIF (souvent des icônes)
    return false if url.include?("logo") || url.include?("icon") || url.include?("placeholder")

    true
  end
end

