# Import automatique de biens immobiliers

## 🎯 Fonctionnalité

Cette fonctionnalité permet d'importer automatiquement les informations d'un bien immobilier en collant simplement le lien de l'annonce.

## 🌐 Sites supportés

- **Jinka** (redirections) - ex: `https://api.jinka.fr/apiv2/alert/redirect_preview?token=...`
- **SeLoger**
- **LeBonCoin**
- **PAP (De Particulier à Particulier)**
- **Bien'ici**
- **Sites génériques** (avec extraction basique)

## 📋 Données extraites

Le service tente d'extraire automatiquement :

- ✅ Titre de l'annonce
- ✅ Prix affiché
- ✅ Surface (m²)
- ✅ Nombre de pièces
- ✅ Nombre de chambres
- ✅ Ville
- ✅ Code postal
- ✅ Type de bien (appartement, maison, etc.)
- ✅ Classe énergétique (DPE)
- ✅ Émissions GES

## 🚀 Utilisation

### Interface utilisateur

1. Allez sur la page "Nouveau bien" ou "Modifier un bien"
2. En haut du formulaire, vous verrez une section "Import automatique"
3. Collez le lien de l'annonce dans le champ
4. Cliquez sur "Importer depuis l'URL"
5. Les données seront automatiquement remplies dans le formulaire
6. Vérifiez et complétez les informations manquantes
7. Enregistrez le bien

### Exemples de liens

```
https://api.jinka.fr/apiv2/alert/redirect_preview?token=4f90eddfeba4e87268ee03eae18d485a&ad=73850207
https://api.jinka.fr/apiv2/alert/redirect_preview?token=48554022be2e86db2b13adb6132414d0&ad=90898543
https://www.seloger.com/annonces/achat/appartement/paris-75/12345.htm
https://www.leboncoin.fr/ventes_immobilieres/12345.htm
```

## 🔧 Architecture technique

### Service : `PropertyScraperService`

Le service principal qui gère l'extraction des données.

**Méthodes principales :**

- `call` : Point d'entrée principal, retourne un Hash avec les données extraites
- `resolve_jinka_redirect` : Résout les redirections Jinka
- `extract_from_*` : Méthodes spécifiques par site

**Utilisation :**

```ruby
scraper = PropertyScraperService.new(url)
property_data = scraper.call

if property_data
  property.update(property_data)
else
  puts scraper.errors
end
```

### Contrôleur : `PropertiesController#import_from_url`

Action qui expose le service via une API JSON.

**Route :** `POST /properties/import_from_url`

**Paramètres :**
```json
{
  "url": "https://..."
}
```

**Réponse succès :**
```json
{
  "success": true,
  "data": {
    "title": "Bel appartement T3",
    "price": 350000,
    "surface": 65.0,
    "rooms": 3,
    ...
  }
}
```

**Réponse erreur :**
```json
{
  "error": "Message d'erreur"
}
```

### Contrôleur Stimulus : `property-importer`

Gère l'interface utilisateur et les appels AJAX.

**Targets :**
- `urlInput` : Champ de saisie de l'URL
- `importButton` : Bouton d'import
- `status` : Zone d'affichage des messages
- `form` : Formulaire à remplir

**Actions :**
- `importFromUrl` : Lance l'import et remplit le formulaire

## 🛠 Améliorations futures

### Court terme
- [ ] Ajouter un système de cache pour éviter de re-scraper la même URL
- [ ] Améliorer l'extraction des adresses complètes
- [ ] Extraire les photos de l'annonce
- [ ] Gérer plus de champs (étage, ascenseur, etc.)

### Moyen terme
- [ ] Ajouter un système d'API officielle avec des partenaires
- [ ] Utiliser des services tiers (Bright Data, ScrapingBee)
- [ ] Ajouter la détection automatique du type de bien
- [ ] Extraire les frais d'agence

### Long terme
- [ ] IA pour améliorer l'extraction
- [ ] Historique des prix pour détecter les baisses
- [ ] Alertes sur les modifications d'annonces
- [ ] Extension navigateur pour import en un clic

## ⚠️ Limitations et considérations

### Légales
- Le scraping doit respecter les CGU des sites
- Utiliser uniquement pour un usage personnel
- Ne pas surcharger les serveurs cibles
- Respecter le fichier robots.txt

### Techniques
- Les sites peuvent changer leur structure HTML
- Certains sites utilisent du JavaScript lourd (nécessite un navigateur headless)
- Les APIs peuvent bloquer les requêtes automatisées
- Timeout de 10 secondes par requête

### Fiabilité
- Toujours vérifier les données extraites
- Certains champs peuvent ne pas être détectés
- La qualité dépend de la structure du site source

## 🧪 Tests

Pour tester le service :

```ruby
# Console Rails
scraper = PropertyScraperService.new("https://...")
result = scraper.call
puts result.inspect
puts scraper.errors if result.nil?
```

## 📝 Notes de développement

### Ajout d'un nouveau site

Pour ajouter le support d'un nouveau site :

1. Ajouter un pattern dans `PropertyScraperService` :
```ruby
NOUVEAUSITE_PATTERN = %r{nouveausite\.com}
```

2. Ajouter le cas dans la méthode `call` :
```ruby
when NOUVEAUSITE_PATTERN
  extract_from_nouveausite(resolved_url)
```

3. Implémenter les méthodes d'extraction :
```ruby
def extract_from_nouveausite(url)
  html = fetch_html(url)
  return nil unless html

  {
    title: extract_nouveausite_title(html),
    price: extract_nouveausite_price(html),
    # ...
  }.compact
end
```

### Debugging

Activer les logs détaillés :
```ruby
# config/environments/development.rb
config.log_level = :debug
```

Vérifier les requêtes HTTP dans les logs Rails.

