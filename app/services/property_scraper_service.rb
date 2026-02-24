require "net/http"
require "json"
require "uri"

class PropertyScraperService
  JINKA_REDIRECT_PATTERN = %r{api\.jinka\.fr/apiv2/alert/redirect_preview}
  SELOGER_PATTERN = %r{seloger\.com}
  LEBONCOIN_PATTERN = %r{leboncoin\.fr}
  PAP_PATTERN = %r{pap\.fr}
  BIENICI_PATTERN = %r{bienici\.com}

  attr_reader :url, :errors

  def initialize(url)
    @url = url
    @errors = []
  end

  def call
    return nil unless valid_url?

    # Résoudre les redirections Jinka
    resolved_url = resolve_jinka_redirect(@url)

    # Extraire les données selon la source
    case resolved_url
    when SELOGER_PATTERN
      extract_from_seloger(resolved_url)
    when LEBONCOIN_PATTERN
      extract_from_leboncoin(resolved_url)
    when PAP_PATTERN
      extract_from_pap(resolved_url)
    when BIENICI_PATTERN
      extract_from_bienici(resolved_url)
    else
      extract_generic(resolved_url)
    end
  rescue StandardError => e
    @errors << "Erreur lors de l'extraction : #{e.message}"
    Rails.logger.error("PropertyScraperService error: #{e.message}\n#{e.backtrace.join("\n")}")
    nil
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

    uri = URI.parse(url)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 10) do |http|
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
      http.request(request)
    end

    case response
    when Net::HTTPRedirection
      response["location"]
    when Net::HTTPOK
      # Parser le HTML pour trouver la vraie URL si nécessaire
      body = response.body
      # Forcer l'encodage UTF-8
      body.force_encoding("UTF-8") if body.encoding.name == "ASCII-8BIT"
      body = body.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")

      if body =~ /window\.location\.href\s*=\s*["']([^"']+)["']/
        $1
      elsif body =~ /href=["']([^"']+)["'][^>]*>.*?Voir l'annonce/i
        $1
      else
        url
      end
    else
      url
    end
  rescue StandardError => e
    Rails.logger.error("Failed to resolve Jinka redirect: #{e.message}")
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

    data = {
      listing_url: url,
      title: json_ld&.dig("name") || extract_meta_content(html, "og:title") || extract_title(html),
      price: extract_generic_price(html, json_ld),
      surface: extract_generic_surface(html),
      rooms: extract_generic_rooms(html),
      city: json_ld&.dig("address", "addressLocality") || extract_generic_city(html),
      postal_code: json_ld&.dig("address", "postalCode")
    }.compact

    data.empty? ? nil : data
  end

  # Helpers pour fetch
  def fetch_html(url)
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
      return html
    end

    @errors << "Impossible de récupérer la page (code #{response.code})"
    nil
  rescue StandardError => e
    @errors << "Erreur réseau : #{e.message}"
    nil
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
end

