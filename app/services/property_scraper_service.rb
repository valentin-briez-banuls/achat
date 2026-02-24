require "net/http"
require "json"
require "uri"
require "digest"
require "cgi"

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

  MAX_REDIRECTS = 5
  USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

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
    is_jinka = jinka_url?(@url)

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

    # Pour les pages Jinka /ad/, on garde l'URL Jinka au lieu de suivre vers Bien'ici
    if @url.match?(JINKA_AD_PATTERN) && resolved_url != @url
      Rails.logger.info("PropertyScraperService: Jinka ad page detected, using Jinka data instead of #{resolved_url}")
      resolved_url = @url
    end

    Rails.logger.info("PropertyScraperService: URL resolved to #{resolved_url}")

    # Avertir seulement si un lien de redirection API Jinka n'a pas pu être résolu
    # (les URLs /ad/ sont des pages complètes, pas des redirections)
    if @url.match?(JINKA_REDIRECT_PATTERN) && resolved_url.match?(JINKA_REDIRECT_PATTERN)
      @errors << "Le lien Jinka a expiré ou ne redirige plus. Utilisez l'URL directe du bien (ouvrez le lien dans votre navigateur et copiez l'URL finale)."
      Rails.logger.warn("PropertyScraperService: Jinka redirect failed - URL unchanged")
    end

    # Extraire les données selon la source
    data = extract_data_for_url(resolved_url)

    return nil unless data

    # Nettoyer et valider les données
    data = clean_and_validate_data(data)

    # Ajouter le géocoding si activé
    if @geocode && data[:city] && data[:postal_code]
      coordinates = geocode_address(data[:city], data[:postal_code], data[:address])
      data.merge!(coordinates) if coordinates
    end

    # Mettre en cache si activé (mais pas pour les URLs Jinka)
    if @use_cache && !jinka_url?(@url)
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

  def extract_and_attach_images(property)
    return unless @extract_images && @image_urls.any?

    extractor = PropertyImageExtractorService.new(nil, @url)
    extractor.download_and_attach_to(property, @image_urls)
    @errors.concat(extractor.errors) if extractor.errors.any?
  end

  private

  def jinka_url?(url)
    url.match?(JINKA_REDIRECT_PATTERN) || url.match?(JINKA_AD_PATTERN)
  end

  def extract_data_for_url(url)
    case url
    when JINKA_AD_PATTERN
      Rails.logger.info("PropertyScraperService: Using Jinka extractor")
      extract_from_jinka(url)
    when SELOGER_PATTERN
      Rails.logger.info("PropertyScraperService: Using SeLoger extractor")
      extract_from_seloger(url)
    when LEBONCOIN_PATTERN
      Rails.logger.info("PropertyScraperService: Using LeBonCoin extractor")
      extract_from_leboncoin(url)
    when PAP_PATTERN
      Rails.logger.info("PropertyScraperService: Using PAP extractor")
      extract_from_pap(url)
    when BIENICI_PATTERN
      Rails.logger.info("PropertyScraperService: Using Bien'ici extractor")
      extract_from_bienici(url)
    when LOGIC_IMMO_PATTERN, ORPI_PATTERN, CENTURY21_PATTERN, LAFORET_PATTERN, FIGARO_IMMO_PATTERN
      Rails.logger.info("PropertyScraperService: Using agency extractor for #{URI.parse(url).host}")
      extract_from_agency_site(url)
    else
      Rails.logger.info("PropertyScraperService: Using generic extractor")
      extract_generic(url)
    end
  end

  # ============================================================================
  # Cache & geocoding
  # ============================================================================

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

  # ============================================================================
  # Validation
  # ============================================================================

  def clean_and_validate_data(data)
    cleaned = {}

    data.each do |key, value|
      next if value.nil?

      if value.is_a?(String)
        value = value.strip
        next if value.empty?
      end

      case key
      when :postal_code
        next unless value.to_s.match?(/\A\d{5}\z/)
      when :energy_class, :ges_class
        value = value.to_s.upcase
        next unless value.match?(/\A[A-G]\z/)
      when :property_type
        value = value.to_sym if value.is_a?(String)
        valid_types = [:appartement, :maison, :terrain, :loft, :duplex]
        next unless valid_types.include?(value)
      when :price, :surface
        value = value.to_f if value.is_a?(String)
        next unless value.is_a?(Numeric) && value > 0
      when :rooms, :bedrooms, :floor, :total_floors
        value = value.to_i if value.is_a?(String)
        next unless value.is_a?(Integer) && value >= 0
      when :latitude, :longitude
        value = value.to_f if value.is_a?(String)
        next unless value.is_a?(Numeric)
      end

      cleaned[key] = value
    end

    required_fields = [:title, :price, :surface, :city]
    missing_fields = required_fields - cleaned.keys

    if missing_fields.any?
      @errors << "Champs obligatoires manquants : #{missing_fields.join(', ')}"
      Rails.logger.warn("PropertyScraperService: Missing required fields: #{missing_fields.join(', ')}")
    end

    cleaned
  end

  def valid_url?
    uri = URI.parse(@url)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    @errors << "URL invalide"
    false
  end

  # ============================================================================
  # HTTP fetch avec suivi de redirections
  # ============================================================================

  def fetch_html(url, use_js = @use_javascript)
    # Essayer avec JavaScript si demandé
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

    # Fetch HTTP avec suivi automatique des redirections
    current_url = url
    MAX_REDIRECTS.times do |i|
      uri = URI.parse(current_url)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 15) do |http|
        request = Net::HTTP::Get.new(uri)
        request["User-Agent"] = USER_AGENT
        request["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
        request["Accept-Language"] = "fr-FR,fr;q=0.9,en;q=0.8"
        request["Accept-Encoding"] = "identity"
        http.request(request)
      end

      case response
      when Net::HTTPRedirection
        location = response["location"]
        # Gérer les URLs relatives dans les redirections
        if location&.start_with?("/")
          parsed = URI.parse(current_url)
          location = "#{parsed.scheme}://#{parsed.host}#{location}"
        end
        Rails.logger.info("PropertyScraperService: HTTP redirect #{response.code} -> #{location}")
        current_url = location
        next
      when Net::HTTPSuccess
        html = response.body
        html.force_encoding("UTF-8") if html.encoding.name == "ASCII-8BIT"
        html = html.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")

        # Détecter les redirections JavaScript dans le HTML
        js_redirect = detect_js_redirect(html, current_url)
        if js_redirect && i < MAX_REDIRECTS - 1
          Rails.logger.info("PropertyScraperService: JS redirect detected -> #{js_redirect}")
          current_url = js_redirect
          next
        end

        extract_images_from_html(html, current_url)
        return html
      else
        @errors << "Impossible de récupérer la page (code #{response.code})"
        Rails.logger.warn("PropertyScraperService: HTTP #{response.code} for #{current_url}")
        return nil
      end
    end

    @errors << "Trop de redirections"
    nil
  rescue StandardError => e
    @errors << "Erreur réseau : #{e.message}"
    Rails.logger.error("PropertyScraperService: Network error: #{e.message}")
    nil
  end

  def detect_js_redirect(html, base_url)
    # Chercher window.location redirections
    if html =~ /window\.location(?:\.href)?\s*=\s*["']([^"']+)["']/
      return make_absolute_url($1, base_url)
    end

    # Chercher meta refresh
    if html =~ /<meta[^>]*http-equiv=["']refresh["'][^>]*content=["']\d+;\s*url=([^"']+)["']/i
      return make_absolute_url($1, base_url)
    end

    nil
  end

  def make_absolute_url(url, base_url)
    return url if url.start_with?("http")

    parsed = URI.parse(base_url)
    if url.start_with?("/")
      "#{parsed.scheme}://#{parsed.host}#{url}"
    else
      "#{parsed.scheme}://#{parsed.host}/#{url}"
    end
  rescue URI::InvalidURIError
    url
  end

  # ============================================================================
  # Extracteurs de données structurées (JSON-LD, __NEXT_DATA__, etc.)
  # ============================================================================

  # Extraire TOUS les blocs JSON-LD et retourner celui qui contient des données immobilières
  def extract_all_json_ld(html)
    blocks = []
    html.scan(/<script[^>]*type=["']application\/ld\+json["'][^>]*>(.*?)<\/script>/mi) do |match|
      parsed = JSON.parse(match[0]) rescue nil
      blocks << parsed if parsed
    end

    return nil if blocks.empty?

    # Chercher le bloc qui contient des données de listing immobilier
    # Priorité: RealEstateListing > Product > Residence > tout bloc avec "offers" ou "price"
    listing_block = blocks.find { |b| b["@type"]&.include?("RealEstateListing") }
    listing_block ||= blocks.find { |b| b["@type"] == "Product" || b["@type"] == "Residence" }
    listing_block ||= blocks.find { |b| b.key?("offers") || b.key?("price") }
    listing_block ||= blocks.find { |b| b.key?("name") && !b["@type"]&.include?("BreadcrumbList") }

    # Si c'est un tableau (certains sites wrappent dans un array)
    if listing_block.is_a?(Array)
      listing_block = listing_block.find { |b| b.is_a?(Hash) && (b.key?("offers") || b.key?("price") || b.key?("name")) }
    end

    listing_block
  end

  # Extraire __NEXT_DATA__ (Next.js - utilisé par LeBonCoin)
  def extract_next_data(html)
    if html =~ /<script[^>]*id=["']__NEXT_DATA__["'][^>]*>(.*?)<\/script>/mi
      JSON.parse($1) rescue nil
    end
  end

  # Extraire les données embarquées dans des variables JavaScript globales
  def extract_embedded_state(html)
    patterns = [
      /window\.__INITIAL_STATE__\s*=\s*(\{.*?\});\s*<\/script>/m,
      /window\.__PRELOADED_STATE__\s*=\s*(\{.*?\});\s*<\/script>/m,
      /window\.initialData\s*=\s*(\{.*?\});\s*<\/script>/m,
      /window\.__data\s*=\s*(\{.*?\});\s*<\/script>/m,
      /window\.__CONFIG__\s*=\s*(\{.*?\});\s*<\/script>/m
    ]

    patterns.each do |pattern|
      if html =~ pattern
        return JSON.parse($1) rescue nil
      end
    end

    nil
  end

  def extract_meta_content(html, property)
    if html =~ /<meta[^>]*property=["']#{Regexp.escape(property)}["'][^>]*content=["']([^"']+)["']/i ||
       html =~ /<meta[^>]*content=["']([^"']+)["'][^>]*property=["']#{Regexp.escape(property)}["']/i ||
       html =~ /<meta[^>]*name=["']#{Regexp.escape(property)}["'][^>]*content=["']([^"']+)["']/i ||
       html =~ /<meta[^>]*content=["']([^"']+)["'][^>]*name=["']#{Regexp.escape(property)}["']/i
      CGI.unescapeHTML($1)
    end
  end

  def extract_title(html)
    if html =~ /<title[^>]*>(.*?)<\/title>/mi
      CGI.unescapeHTML($1.strip)
    end
  end

  # ============================================================================
  # Jinka
  # ============================================================================

  def resolve_jinka_redirect(url)
    return url unless url.match?(JINKA_REDIRECT_PATTERN)

    Rails.logger.info("PropertyScraperService: Resolving Jinka redirect for #{url}")

    redirect_limit = 5
    current_url = url

    redirect_limit.times do
      uri = URI.parse(current_url)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 10) do |http|
        request = Net::HTTP::Get.new(uri)
        request["User-Agent"] = USER_AGENT
        http.request(request)
      end

      case response
      when Net::HTTPRedirection
        current_url = response["location"]
        Rails.logger.info("PropertyScraperService: HTTP redirect to #{current_url}")
        next
      when Net::HTTPOK
        body = response.body
        body.force_encoding("UTF-8") if body.encoding.name == "ASCII-8BIT"
        body = body.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")

        js_redirect = detect_js_redirect(body, current_url)
        if js_redirect
          current_url = js_redirect
          next
        end

        if body =~ /href=["']([^"']+)["'][^>]*>.*?Voir l'annonce/i
          current_url = $1
          Rails.logger.info("PropertyScraperService: Found 'Voir l'annonce' link to #{current_url}")
          next
        end

        break
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

  def extract_from_jinka(url)
    html = fetch_html(url)
    return nil unless html

    # Priorité 1: Données structurées RSC (React Server Components) de Jinka/Next.js
    rsc_data = extract_jinka_rsc_data(html)
    if rsc_data && rsc_data[:price]
      Rails.logger.info("PropertyScraperService: Jinka - extracted data from RSC chunks")

      # Construire le titre depuis les données RSC si pas de og:title
      title = extract_meta_content(html, "og:title")
      title ||= [rsc_data[:type], "#{rsc_data[:rooms]} pièces", "#{rsc_data[:surface]&.to_i}m²", "- #{rsc_data[:city]} (#{rsc_data[:postal_code]})"].compact.join(" ")

      data = {
        listing_url: url,
        title: title,
        price: rsc_data[:price],
        surface: rsc_data[:surface],
        rooms: rsc_data[:rooms],
        bedrooms: rsc_data[:bedrooms],
        city: rsc_data[:city],
        postal_code: rsc_data[:postal_code],
        latitude: rsc_data[:latitude],
        longitude: rsc_data[:longitude],
        property_type: detect_property_type_from_text(rsc_data[:type] || title || ""),
        energy_class: rsc_data[:energy_class],
        ges_class: rsc_data[:ges_class],
        floor: rsc_data[:floor]
      }.compact

      return data
    end

    # Priorité 2: Meta tags + description (og:description contient souvent le prix)
    title = extract_meta_content(html, "og:title") || extract_title(html)
    title_data = parse_title_info(title) if title
    description = extract_meta_content(html, "og:description") || extract_meta_content(html, "description")
    desc_data = parse_description_info(description) if description

    # Prix: description > HTML > title
    price = desc_data&.dig(:price)
    price ||= extract_price_from_html(html)
    price ||= title_data&.dig(:price)

    data = {
      listing_url: url,
      title: title,
      price: price,
      surface: title_data&.dig(:surface) || desc_data&.dig(:surface) || extract_surface_from_html(html),
      rooms: title_data&.dig(:rooms) || desc_data&.dig(:rooms) || extract_rooms_from_html(html),
      bedrooms: title_data&.dig(:bedrooms) || desc_data&.dig(:bedrooms) || extract_bedrooms_from_html(html),
      city: title_data&.dig(:city) || desc_data&.dig(:city),
      postal_code: title_data&.dig(:postal_code) || desc_data&.dig(:postal_code) || extract_postal_code_from_context(html),
      property_type: detect_property_type(html, title),
      energy_class: extract_dpe(html),
      ges_class: extract_ges(html)
    }.compact

    data
  end

  # Extraire les données structurées des chunks RSC (React Server Components) de Jinka
  # Jinka utilise Next.js avec RSC streaming : self.__next_f.push([1, "...JSON..."])
  def extract_jinka_rsc_data(html)
    # Chercher toutes les propriétés dans les chunks RSC
    # Le format est: "rent":215000,"area":95,"room":5,"bedroom":3,"city":"Pollestres",...
    data = {}

    # Extraire les chunks RSC
    rsc_chunks = []
    html.scan(/self\.__next_f\.push\(\[1,"(.+?)"\]\)/) do |match|
      # Décoder les séquences d'échappement JSON
      chunk = match[0].gsub('\\\\', "\x00").gsub('\\"', '"').gsub("\x00", '\\')
      rsc_chunks << chunk
    end

    return nil if rsc_chunks.empty?

    combined = rsc_chunks.join(" ")

    # Extraire le prix (clé "rent" dans les données Jinka = prix de vente)
    if combined =~ /"rent"\s*:\s*(\d+)/
      data[:price] = $1.to_i
    end

    # Surface
    if combined =~ /"area"\s*:\s*(\d+(?:\.\d+)?)/
      data[:surface] = $1.to_f
    end

    # Pièces
    if combined =~ /"room"\s*:\s*(\d+)/
      data[:rooms] = $1.to_i
    end

    # Chambres
    if combined =~ /"bedroom"\s*:\s*(\d+)/
      data[:bedrooms] = $1.to_i
    end

    # Ville
    if combined =~ /"city"\s*:\s*"([^"]+)"/
      data[:city] = $1
    end

    # Code postal
    if combined =~ /"postal_code"\s*:\s*"([^"]+)"/
      data[:postal_code] = $1
    end

    # Type
    if combined =~ /"type"\s*:\s*"([^"]+)"/
      data[:type] = $1
    end

    # DPE et GES
    if combined =~ /"energy_dpe"\s*:\s*"([A-G])"/i
      data[:energy_class] = $1.upcase
    end

    if combined =~ /"energy_ges"\s*:\s*"([A-G])"/i
      data[:ges_class] = $1.upcase
    end

    # Coordonnées GPS
    if combined =~ /"lat"\s*:\s*([\d.]+)/
      data[:latitude] = $1.to_f
    end

    if combined =~ /"lng"\s*:\s*([\d.]+)/
      data[:longitude] = $1.to_f
    end

    # Étage
    if combined =~ /"floor"\s*:\s*(\d+)/
      data[:floor] = $1.to_i
    end

    # Images (array d'URLs)
    if combined =~ /"images"\s*:\s*\[([^\]]+)\]/
      images_str = $1
      images = images_str.scan(/"(https?:\/\/[^"]+)"/).flatten
      if images.any?
        Rails.logger.info("PropertyScraperService: Found #{images.size} images in Jinka RSC data")
        @image_urls.concat(images)
      end
    end

    data[:price] ? data : nil
  end

  # ============================================================================
  # SeLoger - React SPA avec SSR partiel, JSON-LD + meta tags fiables
  # ============================================================================

  def extract_from_seloger(url)
    html = fetch_html(url)
    return nil unless html

    json_ld = extract_all_json_ld(html)
    title = json_ld&.dig("name") || extract_meta_content(html, "og:title") || extract_title(html)
    title_data = parse_title_info(title) if title
    description = extract_meta_content(html, "og:description") || extract_meta_content(html, "description")
    desc_data = parse_description_info(description) if description

    # Prix: JSON-LD > description > regex HTML
    price = json_ld&.dig("offers", "price")&.to_i
    price = nil if price && price < 10000
    price ||= desc_data&.dig(:price)
    price ||= title_data&.dig(:price)
    price ||= extract_price_from_html(html)

    # Surface: description > title > regex HTML
    surface = desc_data&.dig(:surface) || title_data&.dig(:surface) || extract_surface_from_html(html)

    # Ville / CP: JSON-LD > description > title > regex
    city = json_ld&.dig("address", "addressLocality")
    city ||= desc_data&.dig(:city) || title_data&.dig(:city) || extract_city_from_html(html)

    postal_code = json_ld&.dig("address", "postalCode")
    postal_code ||= desc_data&.dig(:postal_code) || title_data&.dig(:postal_code) || extract_postal_code_from_context(html)

    data = {
      listing_url: url,
      title: title,
      price: price,
      surface: surface,
      rooms: desc_data&.dig(:rooms) || title_data&.dig(:rooms) || extract_rooms_from_html(html),
      bedrooms: desc_data&.dig(:bedrooms) || title_data&.dig(:bedrooms) || extract_bedrooms_from_html(html),
      city: city,
      postal_code: postal_code,
      property_type: detect_property_type(html, title),
      energy_class: extract_dpe(html),
      ges_class: extract_ges(html)
    }.compact

    data
  end

  # ============================================================================
  # LeBonCoin - Next.js avec __NEXT_DATA__ SSR
  # ============================================================================

  def extract_from_leboncoin(url)
    html = fetch_html(url)
    return nil unless html

    # Priorité 1: __NEXT_DATA__ (le plus riche et fiable)
    next_data = extract_next_data(html)
    if next_data
      data = extract_leboncoin_from_next_data(next_data, url)
      return data if data && data[:price]
    end

    # Priorité 2: JSON-LD
    json_ld = extract_all_json_ld(html)

    # Priorité 3: Meta tags + title parsing
    title = json_ld&.dig("name") || extract_meta_content(html, "og:title") || extract_title(html)
    title_data = parse_title_info(title) if title
    description = extract_meta_content(html, "og:description")
    desc_data = parse_description_info(description) if description

    price = json_ld&.dig("offers", "price")&.to_i
    price = nil if price && price < 10000
    price ||= title_data&.dig(:price) || desc_data&.dig(:price) || extract_price_from_html(html)

    data = {
      listing_url: url,
      title: title,
      price: price,
      surface: desc_data&.dig(:surface) || title_data&.dig(:surface) || extract_surface_from_html(html),
      rooms: desc_data&.dig(:rooms) || title_data&.dig(:rooms) || extract_rooms_from_html(html),
      bedrooms: desc_data&.dig(:bedrooms) || title_data&.dig(:bedrooms) || extract_bedrooms_from_html(html),
      city: json_ld&.dig("address", "addressLocality") || title_data&.dig(:city) || desc_data&.dig(:city),
      postal_code: json_ld&.dig("address", "postalCode") || title_data&.dig(:postal_code) || desc_data&.dig(:postal_code) || extract_postal_code_from_context(html),
      property_type: detect_property_type(html, title),
      energy_class: extract_dpe(html),
      ges_class: extract_ges(html)
    }.compact

    data
  end

  def extract_leboncoin_from_next_data(next_data, url)
    # Chercher les données de l'annonce dans __NEXT_DATA__
    ad = next_data.dig("props", "pageProps", "ad")
    ad ||= next_data.dig("props", "pageProps", "adDetail")
    return nil unless ad

    Rails.logger.info("PropertyScraperService: Found LeBonCoin ad data in __NEXT_DATA__")

    # Extraire les attributs (surface, pièces, chambres, DPE, GES, etc.)
    attributes = {}
    if ad["attributes"].is_a?(Array)
      ad["attributes"].each do |attr|
        attributes[attr["key"]] = attr["value"] if attr["key"] && attr["value"]
      end
    end

    # Prix
    price = ad["price"]
    price = price.first if price.is_a?(Array)
    price = price.to_i if price

    # Localisation
    location = ad["location"] || {}

    # Images depuis __NEXT_DATA__
    images = ad.dig("images", "urls") || ad.dig("images", "urls_large") || []
    if images.any?
      Rails.logger.info("PropertyScraperService: Found #{images.size} images in __NEXT_DATA__")
      @image_urls.concat(images)
    end

    title = ad["subject"] || ad["title"]
    surface = attributes["square"]&.to_f
    rooms = attributes["rooms"]&.to_i
    bedrooms = attributes["nb_bedrooms"]&.to_i

    data = {
      listing_url: url,
      title: title,
      price: price,
      surface: surface,
      rooms: rooms,
      bedrooms: bedrooms,
      city: location["city"],
      postal_code: location["zipcode"],
      latitude: location["lat"]&.to_f,
      longitude: location["lng"]&.to_f,
      property_type: detect_property_type_from_text(attributes["real_estate_type"] || title || ""),
      energy_class: normalize_energy_class(attributes["energy_rate"]),
      ges_class: normalize_energy_class(attributes["ges"])
    }.compact

    data
  end

  # ============================================================================
  # PAP - HTML relativement simple, SSR correct
  # ============================================================================

  def extract_from_pap(url)
    html = fetch_html(url)
    return nil unless html

    json_ld = extract_all_json_ld(html)
    title = json_ld&.dig("name") || extract_meta_content(html, "og:title") || extract_title(html)
    title_data = parse_title_info(title) if title
    description = extract_meta_content(html, "og:description") || extract_meta_content(html, "description")
    desc_data = parse_description_info(description) if description

    price = json_ld&.dig("offers", "price")&.to_i
    price = nil if price && price < 10000
    price ||= desc_data&.dig(:price) || title_data&.dig(:price) || extract_price_from_html(html)

    data = {
      listing_url: url,
      title: title,
      price: price,
      surface: desc_data&.dig(:surface) || title_data&.dig(:surface) || extract_surface_from_html(html),
      rooms: desc_data&.dig(:rooms) || title_data&.dig(:rooms) || extract_rooms_from_html(html),
      bedrooms: desc_data&.dig(:bedrooms) || title_data&.dig(:bedrooms) || extract_bedrooms_from_html(html),
      city: json_ld&.dig("address", "addressLocality") || desc_data&.dig(:city) || title_data&.dig(:city),
      postal_code: json_ld&.dig("address", "postalCode") || desc_data&.dig(:postal_code) || title_data&.dig(:postal_code) || extract_postal_code_from_context(html),
      property_type: detect_property_type(html, title),
      energy_class: extract_dpe(html),
      ges_class: extract_ges(html)
    }.compact

    data
  end

  # ============================================================================
  # Bien'ici - SPA React, données embarquées dans state JS
  # ============================================================================

  def extract_from_bienici(url)
    html = fetch_html(url)
    return nil unless html

    # Priorité 1: Données embarquées dans le JavaScript (le plus riche)
    embedded = extract_embedded_state(html)
    if embedded
      data = extract_bienici_from_state(embedded, url)
      return data if data && data[:price]
    end

    # Priorité 2: __NEXT_DATA__ (si migration vers Next.js)
    next_data = extract_next_data(html)
    if next_data
      data = extract_bienici_from_next_data(next_data, url)
      return data if data && data[:price]
    end

    # Si peu d'images trouvées et JS disponible, réessayer avec JS rendering
    if @extract_images && @image_urls.size <= 1 && JavascriptRendererService.enabled? && !@use_javascript
      Rails.logger.info("PropertyScraperService: Bien'ici - few images found, retrying with JavaScript")
      html = fetch_html(url, true)
      return nil unless html
    end

    # Priorité 3: JSON-LD + meta tags + title parsing
    json_ld = extract_all_json_ld(html)
    title = json_ld&.dig("name") || extract_meta_content(html, "og:title") || extract_title(html)
    title_data = parse_title_info(title) if title
    description = extract_meta_content(html, "og:description")
    desc_data = parse_description_info(description) if description

    price = json_ld&.dig("offers", "price")&.to_i
    price = nil if price && price < 10000
    price ||= desc_data&.dig(:price) || title_data&.dig(:price) || extract_price_from_html(html)

    data = {
      listing_url: url,
      title: title,
      price: price,
      surface: desc_data&.dig(:surface) || title_data&.dig(:surface) || extract_surface_from_html(html),
      rooms: desc_data&.dig(:rooms) || title_data&.dig(:rooms) || extract_rooms_from_html(html),
      bedrooms: desc_data&.dig(:bedrooms) || title_data&.dig(:bedrooms) || extract_bedrooms_from_html(html),
      city: json_ld&.dig("address", "addressLocality") || desc_data&.dig(:city) || title_data&.dig(:city),
      postal_code: json_ld&.dig("address", "postalCode") || desc_data&.dig(:postal_code) || title_data&.dig(:postal_code) || extract_postal_code_from_context(html),
      property_type: detect_property_type(html, title),
      energy_class: extract_dpe(html),
      ges_class: extract_ges(html)
    }.compact

    data
  end

  def extract_bienici_from_state(state, url)
    # Bien'ici stocke les données dans différentes clés selon la version
    ad = state.dig("adView", "ad") || state.dig("ad") || state.dig("classified")
    return nil unless ad

    Rails.logger.info("PropertyScraperService: Found Bien'ici ad data in embedded state")

    images = ad["photos"]&.map { |p| p["url"] || p["url_large"] || p["original"] } || []
    images = images.compact
    if images.any?
      Rails.logger.info("PropertyScraperService: Found #{images.size} images in embedded state")
      @image_urls.concat(images)
    end

    data = {
      listing_url: url,
      title: ad["title"] || ad["description"]&.truncate(100),
      price: ad["price"]&.to_i,
      surface: ad["surfaceArea"]&.to_f || ad["surface"]&.to_f,
      rooms: ad["roomsQuantity"]&.to_i || ad["rooms"]&.to_i,
      bedrooms: ad["bedroomsQuantity"]&.to_i || ad["bedrooms"]&.to_i,
      city: ad.dig("city", "name") || ad["city"],
      postal_code: ad.dig("city", "postalCode") || ad["postalCode"] || ad["zipCode"],
      latitude: ad.dig("blurredGeoPoint", "lat") || ad.dig("geoPoint", "lat") || ad["lat"],
      longitude: ad.dig("blurredGeoPoint", "lon") || ad.dig("geoPoint", "lon") || ad["lon"],
      property_type: detect_property_type_from_text(ad["propertyType"] || ad["adType"] || ""),
      energy_class: normalize_energy_class(ad["energyClassification"] || ad["energyValue"]),
      ges_class: normalize_energy_class(ad["gesClassification"] || ad["gesValue"]),
      floor: ad["floor"]&.to_i,
      total_floors: ad["floorQuantity"]&.to_i || ad["floorsQuantity"]&.to_i
    }.compact

    data
  end

  def extract_bienici_from_next_data(next_data, url)
    ad = next_data.dig("props", "pageProps", "ad") ||
         next_data.dig("props", "pageProps", "classified") ||
         next_data.dig("props", "pageProps", "realEstateAd")
    return nil unless ad

    extract_bienici_from_state({ "ad" => ad }, url)
  end

  # ============================================================================
  # Extracteur consolidé pour sites d'agences (Orpi, Century21, Laforêt, etc.)
  # Ces sites utilisent généralement JSON-LD + SSR correct
  # ============================================================================

  def extract_from_agency_site(url)
    html = fetch_html(url)
    return nil unless html

    json_ld = extract_all_json_ld(html)
    next_data = extract_next_data(html)
    embedded = extract_embedded_state(html)

    # Essayer toutes les sources de données structurées
    structured_data = json_ld || {}

    # Certains sites d'agences utilisent aussi Next.js
    if next_data
      ad = next_data.dig("props", "pageProps", "property") ||
           next_data.dig("props", "pageProps", "ad") ||
           next_data.dig("props", "pageProps", "listing")
      structured_data = ad if ad.is_a?(Hash) && ad.key?("price")
    end

    title = structured_data.dig("name") || extract_meta_content(html, "og:title") || extract_title(html)
    title_data = parse_title_info(title) if title
    description = extract_meta_content(html, "og:description") || extract_meta_content(html, "description")
    desc_data = parse_description_info(description) if description

    # Prix depuis données structurées
    price = structured_data.dig("offers", "price")&.to_i || structured_data["price"]&.to_i
    price = nil if price && price < 10000
    price ||= desc_data&.dig(:price) || title_data&.dig(:price) || extract_price_from_html(html)

    # Localisation
    city = structured_data.dig("address", "addressLocality") || desc_data&.dig(:city) || title_data&.dig(:city) || extract_city_from_html(html)
    postal_code = structured_data.dig("address", "postalCode") || desc_data&.dig(:postal_code) || title_data&.dig(:postal_code) || extract_postal_code_from_context(html)

    data = {
      listing_url: url,
      title: title,
      price: price,
      surface: desc_data&.dig(:surface) || title_data&.dig(:surface) || extract_surface_from_html(html),
      rooms: desc_data&.dig(:rooms) || title_data&.dig(:rooms) || extract_rooms_from_html(html),
      bedrooms: desc_data&.dig(:bedrooms) || title_data&.dig(:bedrooms) || extract_bedrooms_from_html(html),
      city: city,
      postal_code: postal_code,
      property_type: detect_property_type(html, title),
      energy_class: extract_dpe(html),
      ges_class: extract_ges(html)
    }.compact

    data.empty? ? nil : data
  end

  # ============================================================================
  # Extracteur générique (sites inconnus)
  # ============================================================================

  def extract_generic(url)
    html = fetch_html(url)
    return nil unless html

    json_ld = extract_all_json_ld(html)
    next_data = extract_next_data(html)
    embedded = extract_embedded_state(html)

    title = json_ld&.dig("name") || extract_meta_content(html, "og:title") || extract_title(html)
    title_data = parse_title_info(title) if title
    description = extract_meta_content(html, "og:description") || extract_meta_content(html, "description")
    desc_data = parse_description_info(description) if description

    price = json_ld&.dig("offers", "price")&.to_i
    price = nil if price && price < 10000
    price ||= desc_data&.dig(:price) || title_data&.dig(:price) || extract_price_from_html(html)

    data = {
      listing_url: url,
      title: title,
      price: price,
      surface: desc_data&.dig(:surface) || title_data&.dig(:surface) || extract_surface_from_html(html),
      rooms: desc_data&.dig(:rooms) || title_data&.dig(:rooms) || extract_rooms_from_html(html),
      bedrooms: desc_data&.dig(:bedrooms) || title_data&.dig(:bedrooms) || extract_bedrooms_from_html(html),
      city: json_ld&.dig("address", "addressLocality") || desc_data&.dig(:city) || title_data&.dig(:city) || extract_city_from_html(html),
      postal_code: json_ld&.dig("address", "postalCode") || desc_data&.dig(:postal_code) || title_data&.dig(:postal_code) || extract_postal_code_from_context(html),
      property_type: detect_property_type(html, title),
      energy_class: extract_dpe(html),
      ges_class: extract_ges(html)
    }.compact

    data.empty? ? nil : data
  end

  # ============================================================================
  # Extraction d'images
  # ============================================================================

  def extract_images_from_html(html, url)
    return unless @extract_images
    return if url.match?(JINKA_REDIRECT_PATTERN)

    extractor = PropertyImageExtractorService.new(html, url)
    images = extractor.call
    @image_urls.concat(images) if images.any?
    @errors.concat(extractor.errors) if extractor.errors.any?
  end

  # ============================================================================
  # Extracteurs HTML par regex (fallback quand pas de données structurées)
  # ============================================================================

  # Prix: cherche un nombre >= 50000 suivi de € en évitant les faux positifs
  def extract_price_from_html(html)
    # Chercher dans les zones typiques de prix (balises avec classe contenant "price")
    if html =~ /class=["'][^"']*price[^"']*["'][^>]*>.*?(\d+(?:[\s\u00A0.,]+\d+)*)\s*€/mi
      candidate = $1.gsub(/[\s\u00A0.]+/, "").tr(",", "").to_i
      return candidate if candidate >= 10000
    end

    # Chercher le premier prix significatif (> 50000€) dans tout le HTML
    html.scan(/(\d+(?:[\s\u00A0]+\d+)*)\s*€/).each do |match|
      candidate = match[0].gsub(/[\s\u00A0]+/, "").to_i
      return candidate if candidate >= 50000
    end

    # Dernier recours: chercher un prix avec séparateur de milliers
    if html =~ /(\d{1,3}(?:\.\d{3})+)\s*€/
      return $1.delete(".").to_i
    end

    nil
  end

  # Surface en m²
  def extract_surface_from_html(html)
    # Priorité: chercher dans des zones contextuelles
    if html =~ /surface[^>]*>.*?(\d+(?:[.,]\d+)?)\s*m[²2]/mi
      return $1.tr(",", ".").to_f
    end

    if html =~ /(\d+(?:[.,]\d+)?)\s*m[²2]/i
      $1.tr(",", ".").to_f
    end
  end

  # Nombre de pièces
  def extract_rooms_from_html(html)
    if html =~ /(\d+)\s*pi[èe]ces?/i
      $1.to_i
    end
  end

  # Nombre de chambres
  def extract_bedrooms_from_html(html)
    if html =~ /(\d+)\s*chambres?/i
      $1.to_i
    end
  end

  # Ville - chercher dans des zones contextuelles plutôt que juste un <span class="city">
  def extract_city_from_html(html)
    # Chercher dans une balise avec classe "city" ou "location"
    if html =~ /<[^>]*class=["'][^"']*(?:city|location|locality)[^"']*["'][^>]*>([^<]+)</mi
      city = $1.strip
      return city unless city.empty? || city.match?(/\d{5}/)
    end

    # Chercher un pattern "Ville (XXXXX)" courant en immobilier
    if html =~ /([A-ZÀ-Ÿ][a-zà-ÿ\-\s]+)\s*\((\d{5})\)/
      return $1.strip
    end

    nil
  end

  # Code postal - chercher dans un contexte pertinent (pas n'importe quel nombre à 5 chiffres)
  def extract_postal_code_from_context(html)
    # Chercher dans les données JSON-LD et meta tags (déjà fait ailleurs, ceci est le fallback HTML)

    # Chercher un code postal dans un contexte de ville/adresse
    # Format: "Ville (XXXXX)" ou "XXXXX Ville"
    if html =~ /([A-ZÀ-Ÿ][a-zà-ÿ\-\s]+)\s*\((\d{5})\)/
      return $2
    end

    if html =~ /\b(\d{5})\s+[A-ZÀ-Ÿ][a-zà-ÿ]/
      return $1
    end

    # Chercher dans les attributs data-* ou les champs de formulaire
    if html =~ /(?:postal[_-]?code|zip[_-]?code|code[_-]?postal)[^>]*(?:value|content|data)[^"']*["'](\d{5})["']/i
      return $1
    end

    # Chercher dans les éléments avec des classes contenant "postal" ou "zipcode"
    if html =~ /class=["'][^"']*(?:postal|zipcode|zip-code|cp)[^"']*["'][^>]*>.*?(\d{5})/mi
      return $1
    end

    # Dernier recours: chercher un code postal français dans le titre ou l'adresse
    if html =~ /<(?:h1|h2|address)[^>]*>.*?(\d{5}).*?<\//mi
      return $1
    end

    nil
  end

  # ============================================================================
  # DPE et GES - extraction améliorée
  # ============================================================================

  def extract_dpe(html)
    # Chercher dans des contextes spécifiques au DPE
    patterns = [
      /(?:DPE|diagnostic\s+de\s+performance\s+[eé]nerg[eé]tique)\s*[:\-]?\s*([A-G])\b/i,
      /(?:classe\s+[eé]nerg[eé]tique|[eé]nergie)\s*[:\-]?\s*([A-G])\b/i,
      /(?:energy[_-]?class|dpe[_-]?class|dpe[_-]?rating)[^"']*["']([A-G])["']/i,
      /data-dpe=["']([A-G])["']/i,
      /data-energy[^=]*=["']([A-G])["']/i
    ]

    patterns.each do |pattern|
      if html =~ pattern
        return $1.upcase
      end
    end

    nil
  end

  def extract_ges(html)
    patterns = [
      /(?:GES|gaz\s+[àa]\s+effet\s+de\s+serre)\s*[:\-]?\s*([A-G])\b/i,
      /(?:[eé]missions?\s+(?:de\s+)?GES)\s*[:\-]?\s*([A-G])\b/i,
      /(?:ges[_-]?class|ges[_-]?rating)[^"']*["']([A-G])["']/i,
      /data-ges=["']([A-G])["']/i
    ]

    patterns.each do |pattern|
      if html =~ pattern
        return $1.upcase
      end
    end

    nil
  end

  # ============================================================================
  # Détection du type de bien
  # ============================================================================

  def detect_property_type(html, title = nil)
    text = [title, extract_meta_content(html, "og:title"), extract_meta_content(html, "og:description")].compact.join(" ")
    detect_property_type_from_text(text) || detect_property_type_from_text(html)
  end

  def detect_property_type_from_text(text)
    return nil if text.nil? || text.empty?

    # Chercher dans l'ordre de spécificité
    case text
    when /\bstudio\b/i then "appartement"
    when /\bloft\b/i then "loft"
    when /\bduplex\b/i then "duplex"
    when /\bterrain\b/i then "terrain"
    when /\bmaison\b/i then "maison"
    when /\bappartement\b/i then "appartement"
    when /\bappart\b/i then "appartement"
    when /\bvilla\b/i then "maison"
    when /\bpavillon\b/i then "maison"
    end
  end

  # Normaliser les classes énergétiques (DPE/GES)
  def normalize_energy_class(value)
    return nil if value.nil?

    value = value.to_s.strip.upcase
    return value if value.match?(/\A[A-G]\z/)

    # Certains sites renvoient "D (201-250 kWh/m²/an)" ou juste un nombre
    if value =~ /\b([A-G])\b/
      return $1
    end

    nil
  end

  # ============================================================================
  # Parsing de titre et description (extraction de données structurées du texte)
  # ============================================================================

  def parse_title_info(title)
    return nil unless title

    title = CGI.unescapeHTML(title) if title.include?("&")

    data = {}

    # Extraire la ville - plusieurs patterns possibles :
    # Format 1: "Ville - ..." (ville en début de titre)
    # Format 2: "... - Ville (XXXXX)" (ville après un tiret, suivie d'un code postal)
    # Format 3: "... à Ville" (ville après "à")

    # Priorité: "Ville (XXXXX)" n'importe où dans le titre (le plus fiable)
    if title =~ /[-–—]\s*([A-ZÀ-Ÿ][a-zà-ÿ\-\s']+?)\s*\((\d{5})\)/
      data[:city] = $1.strip
      data[:postal_code] = $2
    elsif title =~ /([A-ZÀ-Ÿ][a-zà-ÿ\-\s']+?)\s*\((\d{5})\)/
      city = $1.strip
      unless city.match?(/\b(?:vente|achat|annonce|bien|immo|maison|appartement|studio)\b/i)
        data[:city] = city
        data[:postal_code] = $2
      end
    elsif title =~ /^([A-ZÀ-ÿ][a-zà-ÿ\-\s']+?)\s*[-–—|]/
      city = $1.strip
      unless city.match?(/\b(?:vente|achat|annonce|bien|immo|seloger|leboncoin)\b/i)
        data[:city] = city
      end
    elsif title =~ /[àa]\s+([A-ZÀ-Ÿ][a-zà-ÿ\-\s']+?)(?:\s*[-–—(,.]|\s*$)/
      data[:city] = $1.strip
    end

    # Extraire le prix (nombre avec espaces possibles suivi de € ou EUR)
    if title =~ /(\d+(?:[\s\u00A0]\d+)*)\s*(?:€|EUR)/i
      price = $1.gsub(/[\s\u00A0]+/, "").to_i
      data[:price] = price if price >= 10000
    end

    # Extraire la surface (nombre suivi de m, m2 ou m²)
    if title =~ /(\d+(?:[.,]\d+)?)\s*m[²2]?(?:\s|$|-|,|\.)/i
      data[:surface] = $1.tr(",", ".").to_f
    end

    # Extraire le nombre de pièces
    if title =~ /(\d+)\s*(?:p\.?|pi[èe]ces?)/i
      data[:rooms] = $1.to_i
    end

    # Extraire le nombre de chambres
    if title =~ /(\d+)\s*(?:ch\.?|chambres?)/i
      data[:bedrooms] = $1.to_i
    end

    # Extraire le code postal depuis le titre (si pas déjà extrait)
    if !data[:postal_code] && title =~ /\b(\d{5})\b/
      data[:postal_code] = $1
    end

    data.empty? ? nil : data
  end

  # Parser les descriptions (meta og:description ou description) pour extraire des données
  def parse_description_info(description)
    return nil unless description

    description = CGI.unescapeHTML(description) if description.include?("&")

    data = {}

    # Prix
    if description =~ /(\d+(?:[\s\u00A0.,]+\d+)*)\s*(?:€|EUR)/i
      price = $1.gsub(/[\s\u00A0.]+/, "").tr(",", "").to_i
      data[:price] = price if price >= 10000
    end

    # Surface
    if description =~ /(\d+(?:[.,]\d+)?)\s*m[²2]/i
      data[:surface] = $1.tr(",", ".").to_f
    end

    # Pièces
    if description =~ /(\d+)\s*pi[èe]ces?/i
      data[:rooms] = $1.to_i
    end

    # Chambres
    if description =~ /(\d+)\s*chambres?/i
      data[:bedrooms] = $1.to_i
    end

    # Ville et code postal (format "Ville (XXXXX)" ou "XXXXX Ville")
    if description =~ /([A-ZÀ-Ÿ][a-zà-ÿ\-\s']+?)\s*\((\d{5})\)/
      data[:city] = $1.strip
      data[:postal_code] = $2
    elsif description =~ /(\d{5})\s+([A-ZÀ-Ÿ][a-zà-ÿ\-\s']+)/
      data[:postal_code] = $1
      data[:city] = $2.strip
    end

    # Code postal seul
    if !data[:postal_code] && description =~ /\b(\d{5})\b/
      data[:postal_code] = $1
    end

    data.empty? ? nil : data
  end
end