#!/usr/bin/env ruby
# Test complet de l'import de propriété

require_relative '../config/environment'

puts "\n=== TEST COMPLET DE L'IMPORT ==="
puts "\n1. URL Markdown (comme reçue du navigateur):"
markdown_url = '[https://api.jinka.fr/apiv2/alert/redirect_preview?token=4f90eddfeba4e87268ee03eae18d485a&ad=73850207](https://api.jinka.fr/apiv2/alert/redirect_preview?token=4f90eddfeba4e87268ee03eae18d485a&ad=73850207)'
puts "   #{markdown_url}"

puts "\n2. Nettoyage de l'URL..."
# Simuler clean_url
url = markdown_url.strip
if url =~ /\[.*?\]\((https?:\/\/[^\)]+)\)/
  url = $1
end
puts "   ✅ URL nettoyée: #{url}"

puts "\n3. Extraction des données avec PropertyScraperService..."
scraper = PropertyScraperService.new(url)
result = scraper.call

if result
  puts "   ✅ Extraction réussie!\n"
  puts "4. Données extraites:"
  result.each do |key, value|
    puts "   • #{key.to_s.ljust(15)}: #{value.inspect}"
  end

  puts "\n✅ SUCCÈS - #{result.keys.size} champs extraits"
  puts "\nCes données seront utilisées pour remplir automatiquement:"
  puts "   - Le champ 'Titre'"
  puts "   - Le champ 'Prix'"
  puts "   - Le champ 'Surface'"
  puts "   - Le champ 'Pièces'" if result[:rooms]
  puts "   - Le champ 'Chambres'" if result[:bedrooms]
  puts "   - Le champ 'Ville'" if result[:city]
  puts "   - Le champ 'Code postal'" if result[:postal_code]
  puts "   - Le champ 'URL de l'annonce'"
else
  puts "   ❌ Erreur lors de l'extraction"
  puts "   Erreurs: #{scraper.errors.inspect}"
end

puts "\n"

