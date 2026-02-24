# ✅ Checklist de déploiement - Import automatique

## Avant de déployer

### 1. Vérifier les fichiers créés
- [ ] `app/services/property_scraper_service.rb` existe
- [ ] `app/javascript/controllers/property_importer_controller.js` existe
- [ ] `app/views/properties/_form.html.erb` modifié avec le bloc d'import
- [ ] `app/controllers/properties_controller.rb` contient `import_from_url`
- [ ] `config/routes.rb` contient la route `POST /properties/import_from_url`

### 2. Tests locaux

#### Test du service
```bash
bin/rails console
```

```ruby
# Test 1 : Service se charge
scraper = PropertyScraperService.new("https://example.com")
puts scraper.class.name  # => PropertyScraperService

# Test 2 : Patterns fonctionnent
jinka_url = "https://api.jinka.fr/apiv2/alert/redirect_preview?token=xxx&ad=123"
scraper = PropertyScraperService.new(jinka_url)
# Devrait détecter Jinka

# Test 3 : Extraction basique (avec une vraie URL si possible)
# scraper = PropertyScraperService.new("URL_REELLE_ICI")
# result = scraper.call
# puts result.inspect
```

#### Test de la route
```bash
bin/rails routes | grep import_from_url
# Devrait afficher : import_from_url_properties POST /properties/import_from_url
```

#### Test de l'interface
```bash
# Démarrer le serveur
bin/dev

# Puis dans un navigateur :
# 1. Aller sur /properties/new
# 2. Vérifier que la zone "Import automatique" s'affiche
# 3. Coller une URL de test
# 4. Vérifier qu'il n'y a pas d'erreur JS (ouvrir la console)
```

### 3. Vérifications de sécurité

- [ ] Le service ne fait pas d'injection SQL
- [ ] Les URLs sont validées avant utilisation
- [ ] Timeout de 10 secondes pour éviter les blocages
- [ ] Autorisation Pundit vérifiée dans le contrôleur
- [ ] Protection CSRF activée

### 4. Performance

- [ ] Timeout configuré (10 secondes)
- [ ] Pas de boucle infinie possible
- [ ] Gestion des erreurs réseau
- [ ] Limite de redirection (implicite via Net::HTTP)

## Après le déploiement

### 1. Tests en production

#### Test basique
```bash
# SSH sur le serveur ou console de production
bin/rails console -e production
```

```ruby
# Vérifier que le service se charge
PropertyScraperService.new("https://example.com").class.name
```

#### Test via curl (remplacer TOKEN et URL)
```bash
curl -X POST https://votre-domaine.com/properties/import_from_url \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: VOTRE_TOKEN" \
  -H "Cookie: _session_id=VOTRE_SESSION" \
  -d '{"url": "https://www.seloger.com/test"}'
```

### 2. Monitoring

#### Logs à surveiller
```bash
# Surveiller les erreurs
tail -f log/production.log | grep PropertyScraperService

# Surveiller les appels à l'API
tail -f log/production.log | grep import_from_url
```

#### Métriques à suivre
- Nombre d'imports par jour
- Taux de succès/échec
- Temps moyen d'extraction
- Sites les plus utilisés

### 3. Tests utilisateurs réels

- [ ] Tester avec un lien Jinka
- [ ] Tester avec SeLoger
- [ ] Tester avec LeBonCoin
- [ ] Tester avec un site non supporté (vérifier le fallback)
- [ ] Tester avec une URL invalide (vérifier le message d'erreur)

## En cas de problème

### Le service ne se charge pas
```ruby
# Vérifier que le fichier existe
File.exist?(Rails.root.join('app/services/property_scraper_service.rb'))

# Recharger le code
Rails.application.reloader.reload!
```

### Erreur JavaScript
```javascript
// Ouvrir la console du navigateur (F12)
// Vérifier les erreurs
// Vérifier que Stimulus est chargé
Stimulus.controllers
```

### Erreur de route
```bash
# Vérifier les routes
bin/rails routes | grep import

# Redémarrer le serveur
```

### Timeout ou lenteur
```ruby
# Dans le service, ajuster le timeout si nécessaire
# Ligne ~72 et ~189 de property_scraper_service.rb
open_timeout: 10,  # Augmenter si nécessaire
read_timeout: 10   # Augmenter si nécessaire
```

## Rollback (en cas de problème majeur)

### 1. Désactiver temporairement
Commenter le bloc d'import dans `_form.html.erb` :
```erb
<%# Temporairement désactivé
<div data-controller="property-importer" ...>
  ...
</div>
%>
```

### 2. Supprimer la route
Commenter dans `routes.rb` :
```ruby
# collection do
#   post :import_from_url
# end
```

### 3. Supprimer les fichiers
```bash
# NE PAS supprimer si possible, juste commenter
# git rm app/services/property_scraper_service.rb
# git rm app/javascript/controllers/property_importer_controller.js
```

## Performance en production

### Optimisations possibles

#### 1. Ajouter un cache
```ruby
# Dans PropertyScraperService
def call
  cache_key = "property_scraper:#{Digest::MD5.hexdigest(@url)}"
  
  Rails.cache.fetch(cache_key, expires_in: 1.hour) do
    # ... logique existante
  end
end
```

#### 2. Job asynchrone (si lent)
```ruby
# Créer un job
class PropertyImportJob < ApplicationJob
  def perform(url, user_id)
    scraper = PropertyScraperService.new(url)
    data = scraper.call
    # Notifier l'utilisateur via WebSocket/ActionCable
  end
end
```

#### 3. Rate limiting
```ruby
# Dans le contrôleur
def import_from_url
  # Limiter à 10 imports par minute par utilisateur
  rate_limit = Redis.current.get("import_rate:#{current_user.id}")
  
  if rate_limit && rate_limit.to_i > 10
    render json: { error: "Trop de requêtes" }, status: 429
    return
  end
  
  # ... reste du code
end
```

## Documentation pour l'équipe

- [ ] Partager le IMPORT_README.md avec l'équipe
- [ ] Former les utilisateurs (si nécessaire)
- [ ] Ajouter dans la documentation produit
- [ ] Créer un ticket de suivi pour les améliorations

## Métriques de succès

### Semaine 1
- [ ] Au moins 10 imports réussis
- [ ] Taux de succès > 70%
- [ ] Aucune erreur serveur

### Mois 1
- [ ] 100+ imports réussis
- [ ] Taux de succès > 80%
- [ ] Feedback utilisateurs positif

### Trimestre 1
- [ ] 500+ imports réussis
- [ ] Support de 2+ nouveaux sites
- [ ] Temps moyen d'ajout de bien < 1 minute

## Notes

- ✅ Pas de dépendances externes ajoutées
- ✅ Compatible Ruby standard library (Net::HTTP)
- ✅ Pas de migration de base de données nécessaire
- ✅ Rétrocompatible (formulaire fonctionne sans JS)
- ✅ Progressive enhancement

## Validation finale

- [ ] ✅ Code committé dans git
- [ ] ✅ Tests locaux passés
- [ ] ✅ Documentation à jour
- [ ] ✅ Équipe informée
- [ ] 🚀 Prêt pour la production !

---

**Date de déploiement :** _________________

**Déployé par :** _________________

**Version :** 1.0.0

**Status :** ☐ En cours  ☐ Terminé  ☐ Rollback

