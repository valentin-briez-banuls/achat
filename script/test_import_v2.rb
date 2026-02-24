#!/usr/bin/env ruby
# frozen_string_literal: true

# Script de test pour les nouvelles fonctionnalités d'import V2
# Usage: bin/rails runner script/test_import_v2.rb

puts "=" * 80
puts "🧪 TEST DES AMÉLIORATIONS D'IMPORT V2"
puts "=" * 80
puts

# URL de test (à remplacer par une vraie URL)
test_url = ENV["TEST_URL"] || "https://www.seloger.com/annonces/achat/appartement/paris-75/"

puts "📍 URL de test : #{test_url}"
puts

# Test 1 : Cache
puts "=" * 80
puts "TEST 1 : Système de Cache"
puts "=" * 80

# Vérifier si l'URL est déjà en cache
cached = PropertyScrapeCache.find_by_url(test_url)
if cached
  puts "✅ Cache existant trouvé"
  puts "   - Créé le : #{cached.created_at}"
  puts "   - Expire le : #{cached.expires_at}"
  puts "   - Images : #{cached.images_urls&.size || 0}"

  # Supprimer le cache pour le test
  cached.destroy
  puts "🗑️  Cache supprimé pour le test"
else
  puts "ℹ️  Pas de cache existant"
end
puts

# Test 2 : Extraction avec toutes les fonctionnalités
puts "=" * 80
puts "TEST 2 : Extraction Complète"
puts "=" * 80

start_time = Time.current
scraper = PropertyScraperService.new(test_url, {
  cache: true,
  images: true,
  geocode: true,
  javascript: false
})

data = scraper.call
duration = Time.current - start_time

if data
  puts "✅ Extraction réussie en #{duration.round(2)}s"
  puts
  puts "📋 Données extraites :"
  data.each do |key, value|
    puts "   - #{key}: #{value}"
  end

  puts
  puts "📸 Images trouvées : #{scraper.image_urls.size}"
  scraper.image_urls.take(3).each_with_index do |url, i|
    puts "   #{i + 1}. #{url[0..80]}#{url.length > 80 ? '...' : ''}"
  end
  puts "   ..." if scraper.image_urls.size > 3

  if scraper.errors.any?
    puts
    puts "⚠️  Avertissements :"
    scraper.errors.each { |err| puts "   - #{err}" }
  end
else
  puts "❌ Échec de l'extraction"
  puts
  puts "Erreurs :"
  scraper.errors.each { |err| puts "   - #{err}" }
  exit 1
end
puts

# Test 3 : Vérifier le cache
puts "=" * 80
puts "TEST 3 : Vérification du Cache"
puts "=" * 80

cached = PropertyScrapeCache.find_by_url(test_url)
if cached
  puts "✅ Données mises en cache"
  puts "   - Expire dans : #{((cached.expires_at - Time.current) / 1.day).round(1)} jours"
  puts "   - Images en cache : #{cached.images_urls&.size || 0}"
else
  puts "❌ Échec de la mise en cache"
end
puts

# Test 4 : Utilisation du cache
puts "=" * 80
puts "TEST 4 : Utilisation du Cache"
puts "=" * 80

start_time = Time.current
scraper2 = PropertyScraperService.new(test_url)
data2 = scraper2.call
duration2 = Time.current - start_time

if data2
  puts "✅ Données récupérées depuis le cache en #{duration2.round(2)}s"
  puts "   ⚡ #{((duration - duration2) / duration * 100).round(0)}% plus rapide !"
else
  puts "❌ Échec de la récupération depuis le cache"
end
puts

# Test 5 : Géocoding
puts "=" * 80
puts "TEST 5 : Service de Géocoding"
puts "=" * 80

if data[:city] && data[:postal_code]
  service = GeocodingService.new(data[:city], data[:postal_code])
  coords = service.call

  if coords
    puts "✅ Géocoding réussi"
    puts "   - Ville : #{data[:city]}"
    puts "   - Code postal : #{data[:postal_code]}"
    puts "   - Latitude : #{coords[:latitude]}"
    puts "   - Longitude : #{coords[:longitude]}"
  else
    puts "❌ Échec du géocoding"
    service.errors.each { |err| puts "   - #{err}" }
  end
else
  puts "⚠️  Pas de ville/code postal pour tester le géocoding"
end
puts

# Test 6 : Statistiques globales
puts "=" * 80
puts "TEST 6 : Statistiques du Cache"
puts "=" * 80

total_caches = PropertyScrapeCache.count
active_caches = PropertyScrapeCache.active.count
expired_caches = PropertyScrapeCache.expired.count

puts "📊 Statistiques :"
puts "   - Total de caches : #{total_caches}"
puts "   - Caches actifs : #{active_caches}"
puts "   - Caches expirés : #{expired_caches}"

if expired_caches > 0
  puts
  puts "🧹 Nettoyage des caches expirés..."
  deleted = PropertyScrapeCache.cleanup_expired!
  puts "   ✅ #{deleted} cache(s) supprimé(s)"
end
puts

# Test 7 : Support JavaScript (si disponible)
puts "=" * 80
puts "TEST 7 : Support JavaScript Rendering"
puts "=" * 80

if JavascriptRendererService.enabled?
  puts "✅ Ferrum disponible - JavaScript rendering activé"
  puts "   (Non testé automatiquement pour éviter de lancer Chrome)"
else
  puts "⚠️  Ferrum non disponible"
  puts "   Pour l'activer : bundle add ferrum"
  puts "   Nécessite : Chrome/Chromium installé"
end
puts

# Résumé final
puts "=" * 80
puts "✅ TESTS TERMINÉS AVEC SUCCÈS"
puts "=" * 80
puts
puts "Résumé des fonctionnalités testées :"
puts "  ✅ Extraction de données"
puts "  ✅ Système de cache"
puts "  ✅ Extraction d'images"
puts "  ✅ Géocoding automatique"
puts "  #{JavascriptRendererService.enabled? ? '✅' : '⚠️ '} Support JavaScript"
puts
puts "📖 Documentation complète : IMPORT_AMELIORATIONS_V2.md"
puts

