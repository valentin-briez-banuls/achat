#!/usr/bin/env ruby
# frozen_string_literal: true

# Test de validation des données
# Usage: bin/rails runner script/test_data_validation.rb

puts "=" * 80
puts "🧪 TEST DE VALIDATION DES DONNÉES"
puts "=" * 80
puts

# Trouver un household pour les tests
household = Household.first
unless household
  puts "❌ Aucun household trouvé. Créez-en un d'abord."
  exit 1
end

# Test 1: Données complètes et valides
puts "Test 1: Données complètes et valides"
puts "-" * 40

property1 = Property.new(
  household: household,
  title: "Appartement test",
  price: 250000,
  surface: 65.5,
  city: "Paris",
  postal_code: "75015",
  energy_class: "C",
  ges_class: "D"
)

if property1.valid?
  puts "✅ Validation réussie"
else
  puts "❌ Erreurs de validation:"
  property1.errors.full_messages.each { |msg| puts "   - #{msg}" }
end
puts

# Test 2: Sans code postal (devrait passer maintenant)
puts "Test 2: Sans code postal"
puts "-" * 40

property2 = Property.new(
  household: household,
  title: "Appartement sans CP",
  price: 250000,
  surface: 65.5,
  city: "Paris",
  postal_code: nil
)

if property2.valid?
  puts "✅ Validation réussie (code postal optionnel)"
else
  puts "❌ Erreurs de validation:"
  property2.errors.full_messages.each { |msg| puts "   - #{msg}" }
end
puts

# Test 3: Code postal invalide (devrait échouer)
puts "Test 3: Code postal invalide"
puts "-" * 40

property3 = Property.new(
  household: household,
  title: "Appartement CP invalide",
  price: 250000,
  surface: 65.5,
  city: "Paris",
  postal_code: "123"
)

if property3.valid?
  puts "⚠️  Validation réussie (mais ne devrait pas)"
else
  puts "✅ Validation échouée comme prévu:"
  property3.errors.full_messages.each { |msg| puts "   - #{msg}" }
end
puts

# Test 4: Sans classes énergétiques (devrait passer)
puts "Test 4: Sans classes énergétiques"
puts "-" * 40

property4 = Property.new(
  household: household,
  title: "Appartement sans DPE",
  price: 250000,
  surface: 65.5,
  city: "Paris",
  postal_code: "75015",
  energy_class: nil,
  ges_class: nil
)

if property4.valid?
  puts "✅ Validation réussie (classes énergétiques optionnelles)"
else
  puts "❌ Erreurs de validation:"
  property4.errors.full_messages.each { |msg| puts "   - #{msg}" }
end
puts

# Test 5: Classes énergétiques vides (devrait passer maintenant)
puts "Test 5: Classes énergétiques vides (strings)"
puts "-" * 40

property5 = Property.new(
  household: household,
  title: "Appartement DPE vide",
  price: 250000,
  surface: 65.5,
  city: "Paris",
  postal_code: "75015",
  energy_class: "",
  ges_class: ""
)

if property5.valid?
  puts "✅ Validation réussie (chaînes vides acceptées)"
else
  puts "❌ Erreurs de validation:"
  property5.errors.full_messages.each { |msg| puts "   - #{msg}" }
end
puts

# Test 6: Classe énergétique invalide (devrait échouer)
puts "Test 6: Classe énergétique invalide"
puts "-" * 40

property6 = Property.new(
  household: household,
  title: "Appartement DPE invalide",
  price: 250000,
  surface: 65.5,
  city: "Paris",
  postal_code: "75015",
  energy_class: "X",
  ges_class: "Y"
)

if property6.valid?
  puts "⚠️  Validation réussie (mais ne devrait pas)"
else
  puts "✅ Validation échouée comme prévu:"
  property6.errors.full_messages.each { |msg| puts "   - #{msg}" }
end
puts

# Test 7: Test du service de nettoyage
puts "Test 7: Service de nettoyage des données"
puts "-" * 40

# Simuler des données sales
dirty_data = {
  title: "  Appartement test  ",
  price: "250000",
  surface: "65.5",
  city: "  Paris  ",
  postal_code: "75015",
  energy_class: "c",  # minuscule
  ges_class: "",      # vide
  rooms: "3",
  invalid_field: "should be removed"
}

# Créer un scraper fictif pour tester la méthode de nettoyage
scraper = PropertyScraperService.new("http://test.com")
cleaned = scraper.send(:clean_and_validate_data, dirty_data)

puts "Données nettoyées:"
cleaned.each do |key, value|
  puts "   #{key}: #{value.inspect}"
end
puts

# Test 8: Données manquantes
puts "Test 8: Données avec champs obligatoires manquants"
puts "-" * 40

incomplete_data = {
  title: "Test",
  price: 100000
  # Manque surface et city
}

scraper2 = PropertyScraperService.new("http://test.com")
cleaned2 = scraper2.send(:clean_and_validate_data, incomplete_data)

if scraper2.errors.any?
  puts "✅ Erreurs détectées comme prévu:"
  scraper2.errors.each { |err| puts "   - #{err}" }
else
  puts "⚠️  Aucune erreur détectée (mais devrait en avoir)"
end
puts

puts "=" * 80
puts "✅ TESTS DE VALIDATION TERMINÉS"
puts "=" * 80
puts
puts "Résumé:"
puts "  - Validations du modèle Property mises à jour"
puts "  - Code postal maintenant optionnel"
puts "  - Classes énergétiques vides acceptées"
puts "  - Service de nettoyage des données opérationnel"
puts

