# Guide de Migration vers Import V2

## Avant de Commencer

Cette mise à jour est **rétrocompatible**. Aucune action immédiate requise.

## Changements de Comportement

### 1. PropertyScraperService

**Avant (V1)** :
```ruby
scraper = PropertyScraperService.new(url)
data = scraper.call
```

**Maintenant (V2)** :
```ruby
# Comportement identique par défaut
scraper = PropertyScraperService.new(url)
data = scraper.call

# Nouvelles options disponibles
scraper = PropertyScraperService.new(url, {
  cache: true,      # Par défaut
  images: true,     # Par défaut
  geocode: true,    # Par défaut
  javascript: false # Par défaut
})

# Nouveaux attributs accessibles
scraper.image_urls  # Array des URLs d'images
scraper.errors      # Array des erreurs
```

### 2. Données Retournées

Les données retournées contiennent maintenant :
- `latitude` et `longitude` (si géocodage réussi)
- Pas de changement pour les autres champs

### 3. API Controller

**Response JSON enrichie** :
```json
{
  "success": true,
  "data": { ... },
  "image_urls": [...],      // NOUVEAU
  "images_count": 5         // NOUVEAU
}
```

Le frontend existant continue de fonctionner car il ignore les champs supplémentaires.

## Migration des Biens Existants

### Géocoder les Biens sans Coordonnées

```ruby
# Script à exécuter une fois
Property.where(latitude: nil).find_each do |property|
  next unless property.city && property.postal_code
  
  service = GeocodingService.new(property.city, property.postal_code, property.address)
  coords = service.call
  
  if coords
    property.update_columns(
      latitude: coords[:latitude],
      longitude: coords[:longitude]
    )
    puts "✅ #{property.title} - Géocodé"
  else
    puts "❌ #{property.title} - Échec"
  end
  
  sleep 1 # Respecter le rate limit Nominatim
end
```

### Ré-importer les Images

Les images ne sont pas automatiquement téléchargées pour les biens existants.

Pour ré-importer les images d'un bien existant :

```ruby
property = Property.find(123)

if property.listing_url.present?
  scraper = PropertyScraperService.new(property.listing_url, images: true)
  data = scraper.call
  
  if scraper.image_urls.any?
    scraper.extract_and_attach_images(property)
    puts "✅ #{scraper.image_urls.size} images attachées"
  end
end
```

## Nettoyage

### Supprimer les Anciens Caches (si nécessaire)

```ruby
# Supprimer tous les caches
PropertyScrapeCache.destroy_all

# Ou seulement les expirés
PropertyScrapeCache.cleanup_expired!
```

## Performance

### Impact Attendu

- **Premier scraping** : +1-2s (géocoding + extraction images)
- **Scraping avec cache** : -90% temps (quasi instantané)
- **Stockage** : +10-50 Ko par bien (cache JSON)
- **Stockage images** : Variable (5-50 Mo par bien si images téléchargées)

### Optimisations Recommandées

1. **Désactiver le géocoding si non nécessaire** :
```ruby
scraper = PropertyScraperService.new(url, geocode: false)
```

2. **Désactiver les images pour les imports rapides** :
```ruby
scraper = PropertyScraperService.new(url, images: false)
```

3. **Utiliser un job asynchrone pour les images** (futur) :
```ruby
# TODO: Implémenter ExtractImagesJob
ExtractImagesJob.perform_later(property.id, scraper.image_urls)
```

## Monitoring

### Logs à Surveiller

```bash
# Scraping général
tail -f log/production.log | grep PropertyScraperService

# Cache
tail -f log/production.log | grep "Cache hit\|Cache miss"

# Géocoding
tail -f log/production.log | grep GeocodingService

# Images
tail -f log/production.log | grep PropertyImageExtractorService
```

### Métriques Recommandées

- Taux de cache hit
- Temps moyen de scraping (avec/sans cache)
- Taux de succès du géocoding
- Nombre d'images extraites par bien
- Espace disque utilisé (Active Storage)

## Rollback (si nécessaire)

Si vous rencontrez des problèmes :

1. **Désactiver toutes les nouvelles fonctionnalités** :
```ruby
# Dans PropertiesController#import_from_url
scraper = PropertyScraperService.new(url, {
  cache: false,
  images: false,
  geocode: false,
  javascript: false
})
```

2. **Supprimer la table de cache** :
```bash
bin/rails db:rollback STEP=1
```

3. **Désinstaller les gems** (si vraiment nécessaire) :
```ruby
# Gemfile - commenter les gems
# gem "geocoder"
# gem "down", "~> 5.0"
# gem "ferrum"
```

## Support

En cas de problème :

1. Vérifier les logs
2. Tester avec le script : `bin/rails runner script/test_import_v2.rb`
3. Consulter la documentation : `IMPORT_AMELIORATIONS_V2.md`

## Checklist Post-Migration

- [ ] Migration exécutée : `bin/rails db:migrate`
- [ ] Gems installées : `bundle install`
- [ ] Tests passés : `bin/rails runner script/test_import_v2.rb`
- [ ] Cache fonctionne : Vérifier les logs
- [ ] Géocoding fonctionne : Tester un import
- [ ] Images extraites : Vérifier le JSON de retour
- [ ] Job récurrent configuré : Voir `config/recurring.yml`
- [ ] Documentation lue : `IMPORT_AMELIORATIONS_V2.md`

## Prochaines Étapes

1. Tester l'import sur quelques URLs
2. Monitorer les performances
3. Ajuster les options selon les besoins
4. Éventuellement géocoder les biens existants
5. Considérer l'extraction asynchrone des images (TODO)

---

**Date** : 24 février 2026  
**Version** : 2.0

