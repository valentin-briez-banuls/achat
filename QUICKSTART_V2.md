# 🚀 Guide de Démarrage Rapide - Import V2

## Pour les Développeurs

### Démarrage

1. **Installation des dépendances**
   ```bash
   bundle install
   ```

2. **Migration de la base de données**
   ```bash
   bin/rails db:migrate
   ```

3. **Test rapide**
   ```bash
   bin/rails runner script/test_import_v2.rb
   ```

### Utilisation de Base

```ruby
# Import simple
scraper = PropertyScraperService.new("https://www.seloger.com/annonces/...")
data = scraper.call

if data
  puts "✅ Données extraites"
  pp data
  puts "📸 Images: #{scraper.image_urls.size}"
else
  puts "❌ Erreurs:"
  pp scraper.errors
end
```

### Import Complet avec Photos

```ruby
# 1. Extraire les données
scraper = PropertyScraperService.new(url)
data = scraper.call

# 2. Créer le bien
property = Property.create!(household: household, **data)

# 3. Attacher les images
scraper.extract_and_attach_images(property) if scraper.image_urls.any?

puts "✅ Bien créé avec #{property.photos.count} photos"
```

### Options Avancées

```ruby
# Désactiver certaines fonctionnalités
scraper = PropertyScraperService.new(url, {
  cache: false,      # Ne pas utiliser le cache
  images: false,     # Ne pas extraire les images
  geocode: false,    # Ne pas géocoder
  javascript: true   # Activer le rendu JS (lent)
})
```

## Pour les Utilisateurs

### Import d'une Annonce

1. Trouvez une annonce sur un site immobilier
2. Copiez l'URL complète
3. Allez sur "Nouveau bien" dans l'application
4. Collez l'URL dans le champ "Import automatique"
5. Cliquez sur "Importer depuis l'URL"
6. ✅ Le formulaire se remplit automatiquement !

### Ce Qui Est Importé

- 📝 Titre de l'annonce
- 💰 Prix
- 📐 Surface
- 🛏️ Nombre de pièces et chambres
- 📍 Ville, code postal, coordonnées GPS
- 🏠 Type de bien
- ⚡ DPE et GES
- 📸 Photos (jusqu'à 10)
- 🔗 Lien de l'annonce

### Sites Supportés

✅ SeLoger • LeBonCoin • PAP • Bien'ici • Logic-immo • Orpi • Century21 • Laforêt • Figaro Immobilier • Jinka

## Commandes Utiles

```bash
# Console Rails
bin/rails console

# Vérifier le cache
PropertyScrapeCache.count
PropertyScrapeCache.active.count

# Nettoyer le cache
PropertyScrapeCache.cleanup_expired!

# Test d'import
bin/rails runner "
  url = 'VOTRE_URL_ICI'
  scraper = PropertyScraperService.new(url)
  pp scraper.call
"

# Géocoder un bien existant
bin/rails runner "
  property = Property.find(123)
  service = GeocodingService.new(property.city, property.postal_code)
  coords = service.call
  property.update!(coords) if coords
"
```

## Troubleshooting

### Import ne fonctionne pas
1. Vérifier les logs : `tail -f log/development.log`
2. Tester l'URL dans la console
3. Vérifier la connexion internet

### Géocoding échoue
- Normal pour certaines petites villes
- Vérifier que ville et code postal sont corrects
- Rate limit : Attendre 1 seconde entre requêtes

### Pas d'images
- Normal pour certains sites
- Les images sont filtrées (pas de logos/icônes)
- Vérifier `scraper.image_urls` pour voir ce qui a été trouvé

### JavaScript rendering ne marche pas
- Nécessite Chrome/Chromium installé
- Par défaut désactivé (performance)
- Activer avec `javascript: true`

## Documentation Complète

- 📖 **Guide technique** : `IMPORT_AMELIORATIONS_V2.md`
- 🔄 **Migration** : `MIGRATION_V2.md`
- 📊 **Résumé implémentation** : `IMPLEMENTATION_V2_SUMMARY.md`
- 📝 **README utilisateur** : `IMPORT_README.md`

## Support

En cas de problème :
1. Consulter la documentation
2. Vérifier les logs
3. Tester avec le script de test
4. Ouvrir une issue avec les détails

---

**Version** : 2.0  
**Dernière mise à jour** : 24 février 2026

