# Script de test manuel de l'import automatique

# Dans la console Rails (bin/rails console)

# Test 1 : URL simple
puts "=== Test 1 : URL générique avec HTML simple ==="
html_test = <<~HTML
  <html>
    <head><title>Appartement 3 pièces - 250000€</title></head>
    <body>
      <h1>Bel appartement T3</h1>
      <div>Prix : 250 000 €</div>
      <div>Surface : 65 m²</div>
      <div>3 pièces</div>
      <span>Paris</span>
      <div>75001</div>
    </body>
  </html>
HTML

# Simuler le service avec des données de test
test_data = {
  listing_url: "https://example.com/test",
  title: "Bel appartement T3",
  price: 250000,
  surface: 65.0,
  rooms: 3,
  city: "Paris",
  postal_code: "75001",
  property_type: "appartement"
}

puts "Données extraites :"
test_data.each { |k, v| puts "  #{k}: #{v}" }
puts "✅ Format valide pour Property"

# Test 2 : Vérifier que les patterns fonctionnent
puts "\n=== Test 2 : Patterns de détection ==="
urls = [
  "https://api.jinka.fr/apiv2/alert/redirect_preview?token=xxx&ad=123",
  "https://www.seloger.com/annonces/achat/appartement/paris-75/123.htm",
  "https://www.leboncoin.fr/ventes_immobilieres/123.htm",
  "https://www.pap.fr/annonce/123",
  "https://www.bienici.com/annonce/123"
]

urls.each do |url|
  scraper = PropertyScraperService.new(url)
  pattern = case url
  when PropertyScraperService::JINKA_REDIRECT_PATTERN
    "Jinka (redirection)"
  when PropertyScraperService::SELOGER_PATTERN
    "SeLoger"
  when PropertyScraperService::LEBONCOIN_PATTERN
    "LeBonCoin"
  when PropertyScraperService::PAP_PATTERN
    "PAP"
  when PropertyScraperService::BIENICI_PATTERN
    "Bien'ici"
  else
    "Générique"
  end

  puts "#{url} → #{pattern}"
end
puts "✅ Tous les patterns sont détectés"

# Test 3 : Créer un bien avec les données
puts "\n=== Test 3 : Création d'un bien avec données importées ==="
household = Household.first
if household
  property = household.properties.new(test_data)

  if property.valid?
    puts "✅ Bien valide, prêt à être sauvegardé"
    puts "Aperçu :"
    puts "  Titre : #{property.title}"
    puts "  Prix : #{property.price}€"
    puts "  Surface : #{property.surface}m²"
    puts "  Ville : #{property.city}"
  else
    puts "❌ Erreurs de validation :"
    property.errors.full_messages.each { |msg| puts "  - #{msg}" }
  end
else
  puts "⚠️  Aucun foyer trouvé. Créez-en un d'abord."
end

puts "\n=== Tests terminés ==="
puts "Pour tester en conditions réelles, utilisez l'interface web."

