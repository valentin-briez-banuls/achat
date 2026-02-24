#!/usr/bin/env ruby
# Test simple de l'extraction d'images

puts "\n" + "=" * 80
puts "TEST EXTRACTION D'IMAGES"
puts "=" * 80 + "\n"

# Lire l'URL depuis les arguments ou utiliser une URL par défaut
url = ARGV[0] || "https://www.seloger.com/annonces/achat/appartement/paris-75/ternes-17eme/201234567.htm"

puts "URL testée : #{url}"
puts "Lancement de l'extraction...\n\n"

# Création du scraper
scraper = PropertyScraperService.new(url, {
  images: true,
  cache: false,
  geocode: false
})

# Extraction
data = scraper.call

# Résultats
puts "\n" + "=" * 80
puts "RÉSULTATS"
puts "=" * 80

if data
  puts "\n✅ Données extraites:"
  puts "   - Titre: #{data[:title]}"
  puts "   - Prix: #{data[:price]} €" if data[:price]
  puts "   - Surface: #{data[:surface]} m²" if data[:surface]
  puts "   - Ville: #{data[:city]}" if data[:city]
else
  puts "\n❌ Échec de l'extraction"
end

puts "\n📸 Images:"
puts "   Total: #{scraper.image_urls.size} image(s)"

if scraper.image_urls.any?
  scraper.image_urls.each_with_index do |img_url, i|
    # Afficher les 100 premiers caractères de chaque URL
    display_url = img_url.length > 100 ? img_url[0..97] + "..." : img_url
    puts "   #{i+1}. #{display_url}"
  end
else
  puts "   ⚠️  Aucune image trouvée"
end

if scraper.errors.any?
  puts "\n❌ Erreurs:"
  scraper.errors.each { |err| puts "   - #{err}" }
end

puts "\n💡 Conseil:"
if scraper.image_urls.empty?
  puts "   - Vérifiez les logs avec: tail -f log/development.log | grep Image"
  puts "   - Le site utilise peut-être du JavaScript (ajoutez javascript: true)"
  puts "   - L'URL est peut-être une redirection (Jinka) qui a expiré"
else
  puts "   ✅ L'extraction d'images fonctionne !"
end

puts "\n" + "=" * 80 + "\n"

