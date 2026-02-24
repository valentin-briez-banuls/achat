# 🚀 Améliorations Avancées de l'Import Automatique

## Résumé des Nouvelles Fonctionnalités

Cette mise à jour majeure ajoute 5 fonctionnalités avancées au système d'import automatique de biens immobiliers :

1. ✅ **Suivi des redirections JavaScript** - Rendu des pages dynamiques avec Ferrum
2. ✅ **Géocoding automatique** - Conversion adresse → coordonnées GPS
3. ✅ **Extraction automatique d'images** - Téléchargement des photos d'annonces
4. ✅ **Système de cache intelligent** - Évite les re-scraping inutiles
5. ✅ **Support étendu multi-plateformes** - 5 nouvelles plateformes supportées

---

## 1. 🔄 Suivi des Redirections JavaScript

### Fonctionnalité

Certains sites utilisent du JavaScript pour charger le contenu dynamiquement. Le nouveau service `JavascriptRendererService` utilise **Ferrum** (Chrome headless) pour rendre les pages JavaScript.

### Utilisation

```ruby
# Activer le rendu JavaScript
scraper = PropertyScraperService.new(url, javascript: true)
data = scraper.call
```

### Configuration

Le rendu JavaScript est désactivé par défaut pour des raisons de performance. Il sera automatiquement utilisé en fallback si le scraping basique échoue.

**Dépendances** : Ferrum nécessite Chrome/Chromium installé sur le système.

---

## 2. 🗺️ Géocoding Automatique

### Fonctionnalité

Convertit automatiquement **ville + code postal** en coordonnées GPS (latitude/longitude) via l'API Nominatim d'OpenStreetMap.

### Service : `GeocodingService`

```ruby
service = GeocodingService.new("Paris", "75001", "10 rue de Rivoli")
result = service.call
# => { latitude: 48.8566, longitude: 2.3522 }
```

### Intégration

Le géocoding est **automatique** lors de l'import. Les coordonnées sont directement ajoutées aux données extraites :

```ruby
scraper = PropertyScraperService.new(url)
data = scraper.call
# data contient maintenant :latitude et :longitude
```

### Configuration

Fichier : `config/initializers/geocoder.rb`

```ruby
Geocoder.configure(
  lookup: :nominatim,  # Provider gratuit OpenStreetMap
  timeout: 5,
  cache: Rails.cache,  # Cache les résultats
  nominatim: {
    host: "nominatim.openstreetmap.org",
    email: "contact@achat-immo.fr"
  }
)
```

**Limites** : Nominatim a un rate limit de 1 requête/seconde. Le cache évite les requêtes répétées.

### Désactiver le géocoding

```ruby
scraper = PropertyScraperService.new(url, geocode: false)
```

---

## 3. 📸 Extraction Automatique d'Images

### Fonctionnalité

Extrait automatiquement les URLs des photos d'annonces depuis :
- JSON-LD (schema.org)
- Meta tags Open Graph
- Balises `<img>` avec classes spécifiques

### Service : `PropertyImageExtractorService`

Le service extrait et filtre les images pertinentes (max 10 par défaut).

### Utilisation Automatique

```ruby
scraper = PropertyScraperService.new(url)
data = scraper.call

# Les URLs d'images sont disponibles
puts scraper.image_urls
# => ["https://example.com/photo1.jpg", "https://example.com/photo2.jpg"]
```

### Téléchargement et Attachement

Les images peuvent être automatiquement téléchargées et attachées à un bien :

```ruby
scraper = PropertyScraperService.new(url)
data = scraper.call

property = Property.create!(data)
scraper.extract_and_attach_images(property)
# Les photos sont maintenant attachées via Active Storage
```

### Filtres

Le service ignore automatiquement :
- SVG et GIF (icônes)
- Images contenant "logo", "icon", "placeholder"
- Data URIs
- URLs trop longues (> 2000 caractères)

### Configuration

```ruby
# Désactiver l'extraction d'images
scraper = PropertyScraperService.new(url, images: false)
```

---

## 4. 💾 Système de Cache Intelligent

### Fonctionnalité

Évite de re-scraper la même URL plusieurs fois. Les résultats sont mis en cache pendant **7 jours**.

### Modèle : `PropertyScrapeCache`

```ruby
# Structure de la table
create_table :property_scrape_caches do |t|
  t.string :url_hash              # SHA256 de l'URL
  t.jsonb :scraped_data           # Données extraites
  t.jsonb :images_urls            # URLs des images
  t.datetime :expires_at          # Date d'expiration
  t.timestamps
end
```

### Utilisation Automatique

Le cache est **automatiquement vérifié** lors de chaque scraping :

```ruby
scraper = PropertyScraperService.new(url)
data = scraper.call  # Vérifie le cache en premier
```

**Logs** :
```
PropertyScraperService: Cache hit for https://example.com/annonce/123
```

### Gestion Manuelle

```ruby
# Vérifier si une URL est en cache
cache = PropertyScrapeCache.find_by_url(url)

# Créer/mettre à jour un cache
PropertyScrapeCache.cache_for_url(url, data, image_urls)

# Nettoyer les caches expirés
PropertyScrapeCache.cleanup_expired!
```

### Désactiver le Cache

```ruby
scraper = PropertyScraperService.new(url, cache: false)
```

### Nettoyage Automatique

Un job récurrent nettoie les caches expirés chaque jour à 3h :

```yaml
# config/recurring.yml
clean_expired_scrape_caches:
  class: CleanExpiredScrapeCachesJob
  schedule: every day at 3am
```

---

## 5. 🌐 Support Multi-Plateformes Étendu

### Nouvelles Plateformes Supportées

| Plateforme | URL Pattern | Extracteur |
|------------|-------------|------------|
| **Logic-immo** | `logic-immo.com` | `extract_from_logic_immo` |
| **Orpi** | `orpi.com` | `extract_from_orpi` |
| **Century21** | `century21.fr` | `extract_from_century21` |
| **Laforêt** | `laforet.com` | `extract_from_laforet` |
| **Figaro Immobilier** | `proprietes.lefigaro.fr` | `extract_from_figaro_immo` |

### Plateformes Existantes (déjà supportées)

- ✅ Jinka (redirections)
- ✅ SeLoger
- ✅ LeBonCoin
- ✅ PAP
- ✅ Bien'ici

### Extraction Générique

Si le site n'est pas reconnu, l'extracteur générique tente d'extraire les données via :
- JSON-LD (schema.org)
- Meta tags Open Graph
- Patterns HTML génériques

### Ajout d'une Nouvelle Plateforme

1. Ajouter le pattern dans les constantes :
```ruby
NOUVEAU_SITE_PATTERN = %r{nouveausite\.com}
```

2. Ajouter dans le `case` statement :
```ruby
when NOUVEAU_SITE_PATTERN
  extract_from_nouveau_site(resolved_url)
```

3. Créer la méthode d'extraction :
```ruby
def extract_from_nouveau_site(url)
  html = fetch_html(url)
  return nil unless html
  
  # Logique d'extraction spécifique...
end
```

---

## 📊 API Response Enrichie

L'endpoint `/properties/import_from_url` retourne maintenant plus d'informations :

```json
{
  "success": true,
  "data": {
    "title": "Appartement T3 75m²",
    "price": 350000,
    "surface": 75.0,
    "rooms": 3,
    "bedrooms": 2,
    "city": "Paris",
    "postal_code": "75015",
    "latitude": 48.8420,
    "longitude": 2.2920,
    "property_type": "appartement",
    "energy_class": "C",
    "ges_class": "D",
    "listing_url": "https://..."
  },
  "image_urls": [
    "https://cdn.example.com/photo1.jpg",
    "https://cdn.example.com/photo2.jpg"
  ],
  "images_count": 2
}
```

---

## 🎨 Interface Utilisateur Améliorée

Le message de succès affiche maintenant le nombre de photos trouvées :

```
✅ 📸 Données importées avec succès ! (5 photos trouvées)
```

---

## ⚙️ Options de Configuration

Le `PropertyScraperService` accepte maintenant des options :

```ruby
PropertyScraperService.new(url, {
  cache: true,        # Utiliser le cache (défaut: true)
  images: true,       # Extraire les images (défaut: true)
  geocode: true,      # Géocoder l'adresse (défaut: true)
  javascript: false   # Utiliser Ferrum (défaut: false)
})
```

---

## 🔧 Installation et Configuration

### 1. Gems Installées

```ruby
# Gemfile
gem "geocoder"      # Géocoding
gem "down", "~> 5.0"  # Téléchargement d'images
gem "ferrum"        # Browser automation
```

### 2. Migration

```bash
bin/rails db:migrate
# Crée la table property_scrape_caches
```

### 3. Configuration Geocoder

Fichier créé : `config/initializers/geocoder.rb`

### 4. Job Récurrent

Configuré dans `config/recurring.yml` pour nettoyer les caches expirés.

---

## 📈 Performance et Limites

### Cache
- **Durée** : 7 jours (configurable via `PropertyScrapeCache::CACHE_DURATION`)
- **Stockage** : JSONB PostgreSQL
- **Nettoyage** : Automatique chaque jour à 3h

### Géocoding
- **Provider** : Nominatim (OpenStreetMap)
- **Rate Limit** : 1 requête/seconde
- **Cache** : Redis/Solid Cache
- **Fallback** : Si échec, les coordonnées restent vides

### Images
- **Maximum** : 10 images par annonce (configurable)
- **Taille max** : 10 Mo par image
- **Formats** : JPG, PNG (SVG/GIF ignorés)
- **Stockage** : Active Storage

### JavaScript Rendering
- **Engine** : Ferrum (Chrome headless)
- **Performance** : ~2-5 secondes par page
- **Utilisation** : Désactivé par défaut
- **Dépendances** : Chrome/Chromium requis

---

## 🧪 Tests

### Test Complet

```ruby
# Dans la console Rails
url = "https://www.seloger.com/annonces/achat/..."

scraper = PropertyScraperService.new(url)
data = scraper.call

puts "✅ Données extraites :"
pp data

puts "\n📸 Images trouvées : #{scraper.image_urls.size}"
scraper.image_urls.each_with_index do |img_url, i|
  puts "  #{i + 1}. #{img_url}"
end

puts "\n❌ Erreurs :" if scraper.errors.any?
pp scraper.errors
```

### Test du Cache

```ruby
# Première extraction (pas de cache)
scraper1 = PropertyScraperService.new(url)
data1 = scraper1.call

# Deuxième extraction (utilise le cache)
scraper2 = PropertyScraperService.new(url)
data2 = scraper2.call

# Vérifier le cache
cache = PropertyScrapeCache.find_by_url(url)
puts "Cache expires at: #{cache.expires_at}"
```

### Test du Géocoding

```ruby
service = GeocodingService.new("Lyon", "69001")
coords = service.call

puts "Latitude: #{coords[:latitude]}"
puts "Longitude: #{coords[:longitude]}"
```

### Test des Images

```ruby
scraper = PropertyScraperService.new(url)
data = scraper.call

property = Property.create!(household: household, **data)
scraper.extract_and_attach_images(property)

puts "Photos attachées : #{property.photos.count}"
```

---

## 🐛 Débogage

### Logs Détaillés

```bash
# Suivre les logs en temps réel
tail -f log/development.log | grep "PropertyScraperService\|GeocodingService\|PropertyImageExtractorService"
```

### Vérifier le Cache

```ruby
# Voir tous les caches actifs
PropertyScrapeCache.active.each do |cache|
  puts "URL hash: #{cache.url_hash}"
  puts "Expires: #{cache.expires_at}"
  puts "Images: #{cache.images_urls&.size || 0}"
end
```

### Nettoyer le Cache Manuellement

```ruby
# Supprimer tous les caches
PropertyScrapeCache.destroy_all

# Supprimer les caches expirés
PropertyScrapeCache.cleanup_expired!
```

---

## 📝 Notes Techniques

### Architecture

```
PropertyScraperService (orchestrateur principal)
├── PropertyScrapeCache (gestion du cache)
├── JavascriptRendererService (rendu JavaScript optionnel)
├── GeocodingService (conversion adresse → GPS)
└── PropertyImageExtractorService (extraction images)
```

### Flux d'Exécution

1. Vérification du cache
2. Résolution des redirections (Jinka)
3. Détection de la plateforme
4. Extraction des données (HTTP ou JavaScript)
5. Extraction des images
6. Géocoding de l'adresse
7. Mise en cache des résultats

### Sécurité

- Rate limiting recommandé au niveau contrôleur
- Validation des URLs
- Taille maximale des images (10 Mo)
- Timeout des requêtes réseau (10s)
- Timeout JavaScript rendering (30s)

---

## 🚀 Évolutions Futures

- [ ] Job asynchrone pour le téléchargement d'images (via Solid Queue)
- [ ] Support de proxies pour éviter les bans
- [ ] Détection automatique de captchas
- [ ] Historique des modifications de prix
- [ ] Webhooks pour surveiller les mises à jour d'annonces
- [ ] API tierce (ScrapingBee, BrightData) en fallback

---

## 📚 Ressources

- [Geocoder Gem](https://github.com/alexreisner/geocoder)
- [Down Gem](https://github.com/janko/down)
- [Ferrum Gem](https://github.com/rubycdp/ferrum)
- [Nominatim Usage Policy](https://operations.osmfoundation.org/policies/nominatim/)
- [Active Storage Guide](https://guides.rubyonrails.org/active_storage_overview.html)

---

**Version** : 2.0  
**Date** : 24 février 2026  
**Auteur** : GitHub Copilot

