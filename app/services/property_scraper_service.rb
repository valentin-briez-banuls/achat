require "net/http"
require "json"
require "uri"
require "digest"

class PropertyScraperService
  JINKA_REDIRECT_PATTERN = %r{api\.jinka\.fr/apiv2/alert/redirect_preview}
  JINKA_AD_PATTERN = %r{jinka\.fr/ad/}
  SELOGER_PATTERN = %r{seloger\.com}
  LEBONCOIN_PATTERN = %r{leboncoin\.fr}
  PAP_PATTERN = %r{pap\.fr}
  BIENICI_PATTERN = %r{bienici\.com}
  LOGIC_IMMO_PATTERN = %r{logic-immo\.com}
  ORPI_PATTERN = %r{orpi\.com}
  CENTURY21_PATTERN = %r{century21\.fr}
  LAFORET_PATTERN = %r{laforet\.com}
  FIGARO_IMMO_PATTERN = %r{proprietes\.lefigaro\.fr}

  attr_reader :url, :errors, :image_urls

  def initialize(url, options = {})
    @url = url
    @errors = []
    @image_urls = []
    @use_cache = options.fetch(:cache, true)
    @extract_images = options.fetch(:images, true)
    @geocode = options.fetch(:geocode, true)
    @use_javascript = options.fetch(:javascript, false)
  end

  def call
    return nil unless valid_url?

    Rails.logger.info("=" * 80)
    Rails.logger.info("PropertyScraperService: Starting scrape for #{@url}")
    Rails.logger.info("  Options: cache=#{@use_cache}, images=#{@extract_images}, geocode=#{@geocode}, js=#{@use_javascript}")

    # Vérifier le cache si activé (sauf pour les URLs Jinka qui expirent)
    is_jinka = @url.match?(JINKA_REDIRECT_PATTERN) || @url.match?(JINKA_AD_PATTERN)

    if @use_cache && !is_jinka
      cached_data = check_cache
      if cached_data
        Rails.logger.info("PropertyScraperService: Cache hit, returning cached data")
        return cached_data
      end
    elsif is_jinka
      Rails.logger.info("PropertyScraperService: Jinka URL detected, bypassing cache")
    end

    # Résoudre les redirections Jinka (API et pages directes)
    resolved_url = resolve_jinka_redirect(@url)
    resolved_url = resolve_jinka_ad_page(resolved_url) if resolved_url.match?(JINKA_AD_PATTERN)

    Rails.logger.info("PropertyScraperService: URL resolved to #{resolved_url}")

    # Vérifier si la résolution Jinka a échoué
    is_jinka_original = @url.match?(JINKA_REDIRECT_PATTERN) || @url.match?(JINKA_AD_PATTERN)
    is_jinka_resolved = resolved_url.match?(JINKA_REDIRECT_PATTERN) || resolved_url.match?(JINKA_AD_PATTERN)

    if is_jinka_original && is_jinka_resolved
      @errors << "Le lien Jinka a expiré ou ne redirige plus. Utilisez l'URL directe du bien (ouvrez le lien dans votre navigateur et copiez l'URL finale)."
      Rails.logger.warn("PropertyScraperService: Jinka redirect failed - URL unchanged")
    end

    # Extraire les données selon la source
    data = case resolved_url
    when SELOGER_PATTERN
      Rails.logger.info("PropertyScraperService: Using SeLoger extractor")
      extract_from_seloger(resolved_url)
    when LEBONCOIN_PATTERN
      Rails.logger.info("PropertyScraperService: Using LeBonCoin extractor")
      extract_from_leboncoin(resolved_url)
    when PAP_PATTERN
      Rails.logger.info("PropertyScraperService: Using PAP extractor")
      extract_from_pap(resolved_url)
    when BIENICI_PATTERN
      Rails.logger.info("PropertyScraperService: Using Bien'ici extractor")
      extract_from_bienici(resolved_url)
    when LOGIC_IMMO_PATTERN
      Rails.logger.info("PropertyScraperService: Using Logic-immo extractor")
      extract_from_logic_immo(resolved_url)
    when ORPI_PATTERN
      Rails.logger.info("PropertyScraperService: Using Orpi extractor")
      extract_from_orpi(resolved_url)
    when CENTURY21_PATTERN
      Rails.logger.info("PropertyScraperService: Using Century21 extractor")
      extract_from_century21(resolved_url)
    when LAFORET_PATTERN
      Rails.logger.info("PropertyScraperService: Using Laforêt extractor")
      extract_from_laforet(resolved_url)
    when FIGARO_IMMO_PATTERN
      Rails.logger.info("PropertyScraperService: Using Figaro Immo extractor")
      extract_from_figaro_immo(resolved_url)
    else
      Rails.logger.info("PropertyScraperService: Using generic extractor")
      extract_generic(resolved_url)
    end

    return nil unless data

    # Nettoyer et valider les données
    data = clean_and_validate_data(data)

    # Ajouter le géocoding si activé
    if @geocode && data[:city] && data[:postal_code]
      coordinates = geocode_address(data[:city], data[:postal_code], data[:address])
      data.merge!(coordinates) if coordinates
    end

    # Mettre en cache si activé (mais pas pour les URLs Jinka)
    is_jinka = @url.match?(JINKA_REDIRECT_PATTERN) || @url.match?(JINKA_AD_PATTERN)
    if @use_cache && !is_jinka
      save_to_cache(data)
    end

    Rails.logger.info("PropertyScraperService: Extraction complete")
    Rails.logger.info("  Data fields: #{data.keys.join(', ')}")
    Rails.logger.info("  Images found: #{@image_urls.size}")
    Rails.logger.info("  Errors: #{@errors.size}")
    Rails.logger.info("=" * 80)

    data
  rescue StandardError => e
    @errors << "Erreur lors de l'extraction : #{e.message}"
    Rails.logger.error("PropertyScraperService error: #{e.message}\n#{e.backtrace&.join("\n")}")
    Rails.logger.info("=" * 80)
    nil
  end

  # Méthode pour extraire et attacher les images à un bien
  def extract_and_attach_images(property)
    return unless @extract_images && @image_urls.any?

    extractor = PropertyImageExtractorService.new(nil, @url)
    extractor.download_and_attach_to(property, @image_urls)
    @errors.concat(extractor.errors) if extractor.errors.any?
  end

  private

  def check_cache
    cache = PropertyScrapeCache.find_by_url(@url)
    return nil unless cache

    Rails.logger.info("PropertyScraperService: Cache hit for #{@url}")
    @image_urls = cache.images_urls || []
    cache.scraped_data.symbolize_keys
  end

  def save_to_cache(data)
    PropertyScrapeCache.cache_for_url(@url, data, @image_urls)
    Rails.logger.info("PropertyScraperService: Cached data for #{@url}")
  rescue StandardError => e
    Rails.logger.error("PropertyScraperService: Failed to cache: #{e.message}")
  end

  def geocode_address(city, postal_code, address = nil)
    service = GeocodingService.new(city, postal_code, address)
    result = service.call

    if result
      Rails.logger.info("PropertyScraperService: Geocoded to #{result[:latitude]}, #{result[:longitude]}")
    else
      @errors.concat(service.errors)
    end

    result
  end

  def clean_and_validate_data(data)
    cleaned = {}

    # Nettoyer chaque champ
    data.each do |key, value|
      # Ignorer les valeurs nil
      next if value.nil?

      # Nettoyer les chaînes vides
      if value.is_a?(String)
        value = value.strip
        next if value.empty?
      end

      # Validation spécifique par champ
      case key
      when :postal_code
        # Ne garder que si c'est un code postal français valide (5 chiffres)
        next unless value.to_s.match?(/\A\d{5}\z/)
      when :energy_class, :ges_class
        # Ne garder que si c'est une classe valide (A-G)
        value = value.to_s.upcase
        next unless value.match?(/\A[A-G]\z/)
      when :property_type
        # Convertir en symbole si c'est une chaîne
        value = value.to_sym if value.is_a?(String)
        # Valider que c'est un type valide
        valid_types = [:appartement, :maison, :terrain, :loft, :duplex]
        next unless valid_types.include?(value)
      when :price, :surface
        # S'assurer que ce sont des nombres positifs
        value = value.to_f if value.is_a?(String)
        next unless value.is_a?(Numeric) && value > 0
      when :rooms, :bedrooms, :floor, :total_floors
        # S'assurer que ce sont des entiers positifs
        value = value.to_i if value.is_a?(String)
        next unless value.is_a?(Integer) && value >= 0
      when :latitude, :longitude
        # S'assurer que ce sont des nombres valides
        value = value.to_f if value.is_a?(String)
        next unless value.is_a?(Numeric)
      end

      cleaned[key] = value
    end

    # S'assurer que les champs obligatoires sont présents
    required_fields = [:title, :price, :surface, :city]
    missing_fields = required_fields - cleaned.keys

    if missing_fields.any?
      @errors << "Champs obligatoires manquants : #{missing_fields.join(', ')}"
      Rails.logger.warn("PropertyScraperService: Missing required fields: #{missing_fields.join(', ')}")
    end

    cleaned
  end

  private

  def valid_url?
    uri = URI.parse(@url)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    @errors << "URL invalide"
    false
  end

  def resolve_jinka_redirect(url)
    return url unless url.match?(JINKA_REDIRECT_PATTERN)

    Rails.logger.info("PropertyScraperService: Resolving Jinka redirect for #{url}")

    # Suivre jusqu'à 5 redirections HTTP
    redirect_limit = 5
    current_url = url

    redirect_limit.times do
      uri = URI.parse(current_url)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 10) do |http|
        request = Net::HTTP::Get.new(uri)
        request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
        http.request(request)
      end

      case response
      when Net::HTTPRedirection
        current_url = response["location"]
        Rails.logger.info("PropertyScraperService: HTTP redirect to #{current_url}")
        next
      when Net::HTTPOK
        # Parser le HTML pour trouver la vraie URL si nécessaire
        body = response.body
        body.force_encoding("UTF-8") if body.encoding.name == "ASCII-8BIT"
        body = body.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")

        if body =~ /window\.location\.href\s*=\s*["']([^"']+)["']/
          current_url = $1
          Rails.logger.info("PropertyScraperService: JS redirect to #{current_url}")
        elsif body =~ /href=["']([^"']+)["'][^>]*>.*?Voir l'annonce/i
          current_url = $1
          Rails.logger.info("PropertyScraperService: Found 'Voir l'annonce' link to #{current_url}")
        else
          # Pas de redirection trouvée, on garde cette URL
          break
        end
      else
        break
      end
    end

    Rails.logger.info("PropertyScraperService: Final URL #{current_url}")
    current_url
  rescue StandardError => e
    Rails.logger.error("Failed to resolve Jinka redirect: #{e.message}")
    url
  end

  def resolve_jinka_ad_page(url)
    return url unless url.match?(JINKA_AD_PATTERN)

    Rails.logger.info("PropertyScraperService: Extracting real URL from Jinka ad page #{url}")

    uri = URI.parse(url)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 10) do |http|
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      body = response.body
      body.force_encoding("UTF-8") if body.encoding.name == "ASCII-8BIT"
      body = body.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")

      # Chercher tous les liens vers des sites immobiliers connus
      known_sites = %w[seloger leboncoin pap bienici century21 logic-immo orpi laforet lefigaro]

      body.scan(/href=["']([^"']+)["']/i) do |match|
        url_candidate = match[0]
        next if url_candidate.include?("jinka.fr")
        next if url_candidate.start_with?("/") || url_candidate.start_with?("#")

        # Vérifier si c'est un site immobilier connu
        if known_sites.any? { |site| url_candidate.include?(site) }
          # Décoder les entités HTML si nécessaire
          url_candidate = CGI.unescapeHTML(url_candidate) if url_candidate.include?("&")
          Rails.logger.info("PropertyScraperService: Found real URL in Jinka page: #{url_candidate}")
          return url_candidate
        end
      end

      # Chercher dans le JSON embarqué
      body.scan(/<script[^>]*type=["']application\/ld\+json["'][^>]*>(.*?)<\/script>/mi) do |match|
        json_content = match[0]
        begin
          data = JSON.parse(json_content)
          if data["url"] && !data["url"].include?("jinka.fr")
            Rails.logger.info("PropertyScraperService: Found URL in JSON-LD: #{data['url']}")
            return data["url"]
          end
        rescue JSON::ParserError
          # Continuer
        end
      end

      Rails.logger.warn("PropertyScraperService: Could not extract real URL from Jinka ad page")
    end

    url
  rescue StandardError => e
    Rails.logger.error("Failed to resolve Jinka ad page: #{e.message}")
    url
  end

  def extract_from_seloger(url)
    html = fetch_html(url)
    return nil unless html

    data = {
      listing_url: url,
      title: extract_seloger_title(html),
      price: extract_seloger_price(html),
      surface: extract_seloger_surface(html),
      rooms: extract_seloger_rooms(html),
      bedrooms: extract_seloger_bedrooms(html),
      city: extract_seloger_city(html),
      postal_code: extract_seloger_postal_code(html),
      property_type: extract_seloger_type(html),
      energy_class: extract_seloger_dpe(html),
      ges_class: extract_seloger_ges(html)
    }.compact

    data
  end

  def extract_from_leboncoin(url)
    html = fetch_html(url)
    return nil unless html

    # LeBonCoin utilise souvent du JS, on essaie d'extraire depuis le JSON-LD
    json_ld = extract_json_ld(html)

    data = {
      listing_url: url,
      title: json_ld&.dig("name") || extract_meta_content(html, "og:title"),
      price: extract_leboncoin_price(html, json_ld),
      surface: extract_leboncoin_surface(html),
      rooms: extract_leboncoin_rooms(html),
      city: json_ld&.dig("address", "addressLocality") || extract_leboncoin_city(html),
      postal_code: json_ld&.dig("address", "postalCode") || extract_leboncoin_postal_code(html),
      property_type: extract_leboncoin_type(html)
    }.compact

    data
  end

  def extract_from_pap(url)
    html = fetch_html(url)
    return nil unless html

    data = {
      listing_url: url,
      title: extract_pap_title(html),
      price: extract_pap_price(html),
      surface: extract_pap_surface(html),
      rooms: extract_pap_rooms(html),
      city: extract_pap_city(html),
      postal_code: extract_pap_postal_code(html),
      property_type: extract_pap_type(html)
    }.compact

    data
  end

  def extract_from_bienici(url)
    html = fetch_html(url)
    return nil unless html

    # Si aucune image trouvée et JS disponible, réessayer avec JS
    if @extract_images && @image_urls.size <= 1 && JavascriptRendererService.enabled? && !@use_javascript
      Rails.logger.info("PropertyScraperService: Bien'ici - few images found, retrying with JavaScript")
      html = fetch_html(url, true) # Force JS rendering
    end

    json_ld = extract_json_ld(html)

    data = {
      listing_url: url,
      title: json_ld&.dig("name") || extract_meta_content(html, "og:title"),
      price: extract_bienici_price(html, json_ld),
      surface: extract_bienici_surface(html),
      rooms: extract_bienici_rooms(html),
      city: extract_bienici_city(html),
      postal_code: extract_bienici_postal_code(html),
      property_type: extract_bienici_type(html),
      energy_class: extract_bienici_dpe(html),
      ges_class: extract_bienici_ges(html)
    }.compact

    data
  end

  def extract_generic(url)
    html = fetch_html(url)
    return nil unless html

    json_ld = extract_json_ld(html)

    title = json_ld&.dig("name") || extract_meta_content(html, "og:title") || extract_title(html)

    # Parser le titre pour extraire des infos structurées (ex: Jinka)
    title_data = parse_title_info(title) if title

    data = {
      listing_url: url,
      title: title,
      price: title_data&.dig(:price) || extract_generic_price(html, json_ld),
      surface: title_data&.dig(:surface) || extract_generic_surface(html),
      rooms: title_data&.dig(:rooms) || extract_generic_rooms(html),
      bedrooms: title_data&.dig(:bedrooms) || extract_generic_bedrooms(html),
      city: title_data&.dig(:city) || json_ld&.dig("address", "addressLocality") || extract_generic_city(html),
      postal_code: json_ld&.dig("address", "postalCode") || extract_generic_postal_code(html),
      property_type: extract_generic_type(html)
    }.compact

    data.empty? ? nil : data
  end

  # Helpers pour fetch
  def fetch_html(url, use_js = @use_javascript)
    # Essayer avec JavaScript si demandé ou si nécessaire
    if use_js && JavascriptRendererService.enabled?
      js_renderer = JavascriptRendererService.new(url)
      html = js_renderer.call

      if html
        extract_images_from_html(html, url)
        return html
      else
        @errors.concat(js_renderer.errors)
        Rails.logger.warn("PropertyScraperService: JS rendering failed, falling back to simple HTTP")
      end
    end

    # Fetch simple HTTP
    uri = URI.parse(url)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 10) do |http|
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
      request["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
      request["Accept-Language"] = "fr-FR,fr;q=0.9,en;q=0.8"
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      # Forcer l'encodage UTF-8 pour éviter les erreurs de regex
      html = response.body
      html.force_encoding("UTF-8") if html.encoding.name == "ASCII-8BIT"
      # Remplacer les caractères invalides
      html = html.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")

      # Extraire les URLs d'images
      extract_images_from_html(html, url)

      return html
    end

    @errors << "Impossible de récupérer la page (code #{response.code})"
    nil
  rescue StandardError => e
    @errors << "Erreur réseau : #{e.message}"
    nil
  end

  def extract_images_from_html(html, url)
    return unless @extract_images

    # Ne pas extraire d'images depuis les pages de redirection Jinka
    return if url.match?(JINKA_REDIRECT_PATTERN)

    extractor = PropertyImageExtractorService.new(html, url)
    images = extractor.call
    @image_urls.concat(images) if images.any?
    @errors.concat(extractor.errors) if extractor.errors.any?
  end

  def extract_json_ld(html)
    # Extraire le JSON-LD schema.org
    if html =~ /<script[^>]*type=["']application\/ld\+json["'][^>]*>(.*?)<\/script>/mi
      JSON.parse($1) rescue nil
    end
  end

  def extract_meta_content(html, property)
    if html =~ /<meta[^>]*property=["']#{Regexp.escape(property)}["'][^>]*content=["']([^"']+)["']/i ||
       html =~ /<meta[^>]*content=["']([^"']+)["'][^>]*property=["']#{Regexp.escape(property)}["']/i
      $1
    end
  end

  def extract_title(html)
    html =~ /<title[^>]*>(.*?)<\/title>/mi ? $1.strip : nil
  end

  # SeLoger extractors
  def extract_seloger_title(html)
    if html =~ /<h1[^>]*class=["'][^"']*title[^"']*["'][^>]*>(.*?)<\/h1>/mi
      $1.strip.gsub(/<[^>]+>/, "")
    end
  end

  def extract_seloger_price(html)
    if html =~ /(\d+(?:\s*\d+)*)\s*€/
      $1.gsub(/\s+/, "").to_i
    end
  end

  def extract_seloger_surface(html)
    if html =~ /(\d+(?:[.,]\d+)?)\s*m[²2]/i
      $1.tr(",", ".").to_f
    end
  end

  def extract_seloger_rooms(html)
    if html =~ /(\d+)\s*pi[èe]ces?/i
      $1.to_i
    end
  end

  def extract_seloger_bedrooms(html)
    if html =~ /(\d+)\s*chambres?/i
      $1.to_i
    end
  end

  def extract_seloger_city(html)
    if html =~ /<span[^>]*class=["'][^"']*city[^"']*["'][^>]*>(.*?)<\/span>/mi ||
       html =~ /Ville\s*:\s*<[^>]+>(.*?)</mi
      $1.strip
    end
  end

  def extract_seloger_postal_code(html)
    if html =~ /\b(\d{5})\b/
      $1
    end
  end

  def extract_seloger_type(html)
    case html
    when /\bmaison\b/i then "maison"
    when /\bappartement\b/i then "appartement"
    when /\bloft\b/i then "loft"
    when /\bduplex\b/i then "duplex"
    when /\bterrain\b/i then "terrain"
    end
  end

  def extract_seloger_dpe(html)
    if html =~ /DPE\s*[:\-]?\s*([A-G])/i
      $1.upcase
    end
  end

  def extract_seloger_ges(html)
    if html =~ /GES\s*[:\-]?\s*([A-G])/i
      $1.upcase
    end
  end

  # LeBonCoin extractors
  def extract_leboncoin_price(html, json_ld)
    price = json_ld&.dig("offers", "price") || json_ld&.dig("price")
    return price.to_i if price

    if html =~ /(\d+(?:\s*\d+)*)\s*€/
      $1.gsub(/\s+/, "").to_i
    end
  end

  def extract_leboncoin_surface(html)
    if html =~ /(\d+(?:[.,]\d+)?)\s*m[²2]/i
      $1.tr(",", ".").to_f
    end
  end

  def extract_leboncoin_rooms(html)
    if html =~ /(\d+)\s*pi[èe]ces?/i
      $1.to_i
    end
  end

  def extract_leboncoin_city(html)
    if html =~ /<span[^>]*>([^<]+)<\/span>[^<]*<span[^>]*>\d{5}/mi
      $1.strip
    end
  end

  def extract_leboncoin_postal_code(html)
    if html =~ /\b(\d{5})\b/
      $1
    end
  end

  def extract_leboncoin_type(html)
    case html
    when /\bmaison\b/i then "maison"
    when /\bappartement\b/i then "appartement"
    when /\bloft\b/i then "loft"
    when /\bduplex\b/i then "duplex"
    when /\bterrain\b/i then "terrain"
    end
  end

  # PAP extractors
  def extract_pap_title(html)
    if html =~ /<h1[^>]*>(.*?)<\/h1>/mi
      $1.strip.gsub(/<[^>]+>/, "")
    end
  end

  def extract_pap_price(html)
    if html =~ /(\d+(?:\s*\d+)*)\s*€/
      $1.gsub(/\s+/, "").to_i
    end
  end

  def extract_pap_surface(html)
    if html =~ /(\d+(?:[.,]\d+)?)\s*m[²2]/i
      $1.tr(",", ".").to_f
    end
  end

  def extract_pap_rooms(html)
    if html =~ /(\d+)\s*pi[èe]ces?/i
      $1.to_i
    end
  end

  def extract_pap_city(html)
    if html =~ /<span[^>]*class=["'][^"']*city[^"']*["'][^>]*>(.*?)<\/span>/mi
      $1.strip
    end
  end

  def extract_pap_postal_code(html)
    if html =~ /\b(\d{5})\b/
      $1
    end
  end

  def extract_pap_type(html)
    case html
    when /\bmaison\b/i then "maison"
    when /\bappartement\b/i then "appartement"
    when /\bloft\b/i then "loft"
    when /\bduplex\b/i then "duplex"
    when /\bterrain\b/i then "terrain"
    end
  end

  # BienIci extractors
  def extract_bienici_price(html, json_ld)
    price = json_ld&.dig("offers", "price") || json_ld&.dig("price")
    return price.to_i if price

    if html =~ /(\d+(?:\s*\d+)*)\s*€/
      $1.gsub(/\s+/, "").to_i
    end
  end

  def extract_bienici_surface(html)
    if html =~ /(\d+(?:[.,]\d+)?)\s*m[²2]/i
      $1.tr(",", ".").to_f
    end
  end

  def extract_bienici_rooms(html)
    if html =~ /(\d+)\s*pi[èe]ces?/i
      $1.to_i
    end
  end

  def extract_bienici_city(html)
    if html =~ /<span[^>]*class=["'][^"']*city[^"']*["'][^>]*>(.*?)<\/span>/mi
      $1.strip
    end
  end

  def extract_bienici_postal_code(html)
    if html =~ /\b(\d{5})\b/
      $1
    end
  end

  def extract_bienici_type(html)
    case html
    when /\bmaison\b/i then "maison"
    when /\bappartement\b/i then "appartement"
    when /\bloft\b/i then "loft"
    when /\bduplex\b/i then "duplex"
    when /\bterrain\b/i then "terrain"
    end
  end

  def extract_bienici_dpe(html)
    if html =~ /DPE\s*[:\-]?\s*([A-G])/i
      $1.upcase
    end
  end

  def extract_bienici_ges(html)
    if html =~ /GES\s*[:\-]?\s*([A-G])/i
      $1.upcase
    end
  end

  # Generic extractors
  def extract_generic_price(html, json_ld)
    price = json_ld&.dig("offers", "price") || json_ld&.dig("price")
    return price.to_i if price

    if html =~ /(\d+(?:\s*\d+)*)\s*€/
      $1.gsub(/\s+/, "").to_i
    end
  end

  def extract_generic_surface(html)
    if html =~ /(\d+(?:[.,]\d+)?)\s*m[²2]/i
      $1.tr(",", ".").to_f
    end
  end

  def extract_generic_rooms(html)
    if html =~ /(\d+)\s*pi[èe]ces?/i
      $1.to_i
    end
  end

  def extract_generic_city(html)
    if html =~ /<span[^>]*class=["'][^"']*city[^"']*["'][^>]*>(.*?)<\/span>/mi
      $1.strip
    end
  end

  def extract_generic_bedrooms(html)
    if html =~ /(\d+)\s*chambres?/i
      $1.to_i
    end
  end

  def extract_generic_postal_code(html)
    if html =~ /\b(\d{5})\b/
      $1
    end
  end

  def extract_generic_type(html)
    case html
    when /\bmaison\b/i
      "maison"
    when /\bappartement\b/i
      "appartement"
    when /\bstudio\b/i
      "appartement"
    when /\bloft\b/i
      "loft"
    when /\bduplex\b/i
      "duplex"
    else
      nil
    end
  end

  # Logic-immo extractors
  def extract_from_logic_immo(url)
    html = fetch_html(url)
    return nil unless html

    json_ld = extract_json_ld(html)

    data = {
      listing_url: url,
      title: json_ld&.dig("name") || extract_meta_content(html, "og:title"),
      price: extract_generic_price(html, json_ld),
      surface: extract_generic_surface(html),
      rooms: extract_generic_rooms(html),
      bedrooms: extract_generic_bedrooms(html),
      city: json_ld&.dig("address", "addressLocality") || extract_generic_city(html),
      postal_code: json_ld&.dig("address", "postalCode") || extract_generic_postal_code(html),
      property_type: extract_generic_type(html),
      energy_class: extract_dpe_generic(html),
      ges_class: extract_ges_generic(html)
    }.compact

    data.empty? ? nil : data
  end

  # Orpi extractors
  def extract_from_orpi(url)
    html = fetch_html(url)
    return nil unless html

    json_ld = extract_json_ld(html)

    data = {
      listing_url: url,
      title: json_ld&.dig("name") || extract_meta_content(html, "og:title"),
      price: extract_generic_price(html, json_ld),
      surface: extract_generic_surface(html),
      rooms: extract_generic_rooms(html),
      bedrooms: extract_generic_bedrooms(html),
      city: json_ld&.dig("address", "addressLocality") || extract_generic_city(html),
      postal_code: json_ld&.dig("address", "postalCode") || extract_generic_postal_code(html),
      property_type: extract_generic_type(html),
      energy_class: extract_dpe_generic(html),
      ges_class: extract_ges_generic(html)
    }.compact

    data.empty? ? nil : data
  end

  # Century21 extractors
  def extract_from_century21(url)
    html = fetch_html(url)
    return nil unless html

    json_ld = extract_json_ld(html)

    data = {
      listing_url: url,
      title: json_ld&.dig("name") || extract_meta_content(html, "og:title"),
      price: extract_generic_price(html, json_ld),
      surface: extract_generic_surface(html),
      rooms: extract_generic_rooms(html),
      bedrooms: extract_generic_bedrooms(html),
      city: json_ld&.dig("address", "addressLocality") || extract_generic_city(html),
      postal_code: json_ld&.dig("address", "postalCode") || extract_generic_postal_code(html),
      property_type: extract_generic_type(html),
      energy_class: extract_dpe_generic(html),
      ges_class: extract_ges_generic(html)
    }.compact

    data.empty? ? nil : data
  end

  # Laforêt extractors
  def extract_from_laforet(url)
    html = fetch_html(url)
    return nil unless html

    json_ld = extract_json_ld(html)

    data = {
      listing_url: url,
      title: json_ld&.dig("name") || extract_meta_content(html, "og:title"),
      price: extract_generic_price(html, json_ld),
      surface: extract_generic_surface(html),
      rooms: extract_generic_rooms(html),
      bedrooms: extract_generic_bedrooms(html),
      city: json_ld&.dig("address", "addressLocality") || extract_generic_city(html),
      postal_code: json_ld&.dig("address", "postalCode") || extract_generic_postal_code(html),
      property_type: extract_generic_type(html),
      energy_class: extract_dpe_generic(html),
      ges_class: extract_ges_generic(html)
    }.compact

    data.empty? ? nil : data
  end

  # Figaro Immobilier extractors
  def extract_from_figaro_immo(url)
    html = fetch_html(url)
    return nil unless html

    json_ld = extract_json_ld(html)

    data = {
      listing_url: url,
      title: json_ld&.dig("name") || extract_meta_content(html, "og:title"),
      price: extract_generic_price(html, json_ld),
      surface: extract_generic_surface(html),
      rooms: extract_generic_rooms(html),
      bedrooms: extract_generic_bedrooms(html),
      city: json_ld&.dig("address", "addressLocality") || extract_generic_city(html),
      postal_code: json_ld&.dig("address", "postalCode") || extract_generic_postal_code(html),
      property_type: extract_generic_type(html),
      energy_class: extract_dpe_generic(html),
      ges_class: extract_ges_generic(html)
    }.compact

    data.empty? ? nil : data
  end

  # Extracteurs génériques pour DPE et GES
  def extract_dpe_generic(html)
    if html =~ /DPE\s*[:\-]?\s*([A-G])/i || html =~ /Classe\s+énergétique\s*[:\-]?\s*([A-G])/i
      $1.upcase
    end
  end

  def extract_ges_generic(html)
    if html =~ /GES\s*[:\-]?\s*([A-G])/i || html =~ /Émissions?\s+(?:de\s+)?GES\s*[:\-]?\s*([A-G])/i
      $1.upcase
    end
  end

  def parse_title_info(title)
    return nil unless title

    data = {}

    # Parser les formats comme "Ville - Prix€ - Surface m - Xp. - Xch."
    # Ex: "Alenya - 169000€ - 100m - 4p. - 3ch. - via une agence"

    # Extraire la ville (premier mot avant un tiret ou après certains patterns)
    if title =~ /^([A-ZÀ-ÿ][a-zà-ÿ\-\s]+?)\s*[-–—]/
      data[:city] = $1.strip
    end

    # Extraire le prix (nombre suivi de € ou EUR)
    if title =~ /(\d+(?:\s?\d+)*)\s*€/
      data[:price] = $1.gsub(/\s+/, "").to_i
    end

    # Extraire la surface (nombre suivi de m, m2 ou m²)
    if title =~ /(\d+(?:[.,]\d+)?)\s*m[²2]?(?:\s|$|-)/i
      data[:surface] = $1.tr(",", ".").to_f
    end

    # Extraire le nombre de pièces (nombre suivi de p. ou pièces)
    if title =~ /(\d+)\s*(?:p\.|pièces?)/i
      data[:rooms] = $1.to_i
    end

    # Extraire le nombre de chambres (nombre suivi de ch. ou chambres)
    if title =~ /(\d+)\s*(?:ch\.|chambres?)/i
      data[:bedrooms] = $1.to_i
    end

    data.empty? ? nil : data
  end
end

