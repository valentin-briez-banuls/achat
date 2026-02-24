#!/usr/bin/env ruby
# Debug extraction images Jinka

url = "https://api.jinka.fr/apiv2/alert/redirect_preview?token=4f90eddfeba4e87268ee03eae18d485a&ad=73850207"

puts "=" * 80
puts "DEBUG EXTRACTION JINKA"
puts "=" * 80
puts
puts "URL: #{url}"
puts

# Étape 1 : Résolution de la redirection
puts "ETAPE 1: Resolution de la redirection Jinka"
puts "-" * 40

require "net/http"
require "uri"

uri = URI.parse(url)
response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 10) do |http|
  request = Net::HTTP::Get.new(uri)
  request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
  http.request(request)
end

resolved_url = nil
case response
when Net::HTTPRedirection
  resolved_url = response["location"]
  puts "Redirection HTTP vers: #{resolved_url}"
when Net::HTTPOK
  body = response.body
  body.force_encoding("UTF-8") if body.encoding.name == "ASCII-8BIT"

  if body =~ /window\.location\.href\s*=\s*["']([^"']+)["']/
    resolved_url = $1
    puts "Redirection JavaScript vers: #{resolved_url}"
  elsif body =~ /href=["']([^"']+)["'][^>]*>.*?Voir l'annonce/i
    resolved_url = $1
    puts "Lien 'Voir l'annonce' vers: #{resolved_url}"
  else
    puts "Pas de redirection trouvee dans le HTML"
    puts "Debut du HTML (200 chars):"
    puts body[0..200]
  end
else
  puts "Reponse inattendue: #{response.code}"
end

puts
puts "URL finale: #{resolved_url || url}"
puts

# Étape 2 : Extraction via le service
puts "ETAPE 2: Extraction via PropertyScraperService"
puts "-" * 40

scraper = PropertyScraperService.new(url, images: true, cache: false)
data = scraper.call

if data
  puts "✅ Donnees extraites:"
  puts "  - Titre: #{data[:title]}"
  puts "  - Prix: #{data[:price]}"
  puts "  - Surface: #{data[:surface]}"
else
  puts "❌ Aucune donnee extraite"
end

puts
puts "Images:"
puts "  Nombre: #{scraper.image_urls.size}"
if scraper.image_urls.any?
  scraper.image_urls.each_with_index do |img, i|
    puts "  #{i+1}. #{img[0..80]}#{img.length > 80 ? '...' : ''}"
  end
else
  puts "  ❌ Aucune image trouvee"
end

if scraper.errors.any?
  puts
  puts "Erreurs:"
  scraper.errors.each { |e| puts "  - #{e}" }
end

# Étape 3 : Récupération manuelle du HTML de l'URL finale
if resolved_url && resolved_url != url
  puts
  puts "ETAPE 3: Analyse manuelle de l'URL finale"
  puts "-" * 40

  begin
    uri = URI.parse(resolved_url)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 10) do |http|
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "Mozilla/5.0"
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      html = response.body
      html.force_encoding("UTF-8") if html.encoding.name == "ASCII-8BIT"

      # Recherche d'images
      puts "Recherche d'images dans le HTML:"

      # Meta OG
      og_images = html.scan(/<meta[^>]*property=["']og:image["'][^>]*content=["']([^"']+)["']/i)
      puts "  - Open Graph: #{og_images.size} image(s)"

      # IMG tags
      img_tags = html.scan(/<img[^>]*src=["']([^"']+)["']/i)
      puts "  - Balises IMG: #{img_tags.size} image(s)"

      # Data-src
      data_src = html.scan(/<img[^>]*data-src=["']([^"']+)["']/i)
      puts "  - Data-src: #{data_src.size} image(s)"

      # JSON-LD
      if html =~ /<script[^>]*type=["']application\/ld\+json["'][^>]*>(.*?)<\/script>/mi
        puts "  - JSON-LD: Trouve"
      else
        puts "  - JSON-LD: Non trouve"
      end

      # Patterns immobiliers
      property_imgs = html.scan(/<img[^>]*class=["'][^"']*(?:property|gallery|photo|annonce)[^"']*["'][^>]*src=["']([^"']+)["']/i)
      puts "  - Images immobilieres (class): #{property_imgs.size} image(s)"

      puts
      puts "Taille du HTML: #{html.bytesize} bytes"

    else
      puts "Erreur HTTP: #{response.code}"
    end
  rescue => e
    puts "Erreur: #{e.message}"
  end
end

puts
puts "=" * 80

