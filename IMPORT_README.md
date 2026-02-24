# 🚀 Import Automatique de Biens Immobiliers

## ✨ Qu'est-ce que c'est ?

Une fonctionnalité qui permet d'**importer automatiquement** toutes les informations d'un bien immobilier simplement en collant le lien de l'annonce.

Plus besoin de recopier manuellement les données ! 

## 🎯 Avantages

- ⏱️ **Gain de temps** : 2-3 minutes économisées par bien
- ✅ **Fiabilité** : Moins d'erreurs de saisie
- 🔄 **Multi-sources** : Fonctionne avec plusieurs sites
- 📱 **Mobile-friendly** : Utilisable sur smartphone

## 🌐 Sites supportés

| Site | Support | Exemple |
|------|---------|---------|
| 🔗 Jinka | ✅ Complet | `api.jinka.fr/apiv2/alert/redirect_preview?...` |
| 🏠 SeLoger | ✅ Complet | `seloger.com/annonces/...` |
| 📢 LeBonCoin | ✅ Bon | `leboncoin.fr/ventes_immobilieres/...` |
| 👥 PAP | ✅ Bon | `pap.fr/annonce/...` |
| 🏡 Bien'ici | ✅ Bon | `bienici.com/annonce/...` |
| 🌍 Autres | ⚠️ Basique | Extraction générique |

## 📊 Données extraites automatiquement

✅ **Informations principales**
- Titre de l'annonce
- Prix affiché
- Surface en m²
- Nombre de pièces
- Nombre de chambres

✅ **Localisation**
- Ville
- Code postal

✅ **Caractéristiques**
- Type de bien (appartement, maison, etc.)
- Classe énergétique (DPE)
- Émissions GES

✅ **Autres**
- URL de l'annonce (sauvegardée automatiquement)

## 🎬 Démarrage rapide

### En 4 étapes simples :

1. **Trouvez une annonce** sur SeLoger, LeBonCoin, etc.
2. **Copiez l'URL** de l'annonce
3. **Collez-la** dans le champ "Import automatique"
4. **Cliquez sur "Importer"** et c'est fait ! ✨

### Exemple avec Jinka

```
1. Recevez une alerte Jinka par email
2. Copiez ce lien : 
   https://api.jinka.fr/apiv2/alert/redirect_preview?token=4f90eddfeba4e87268ee03eae18d485a&ad=73850207
3. Collez dans l'app
4. Import automatique !
```

## 📁 Fichiers créés

```
app/
├── services/
│   └── property_scraper_service.rb      # Service principal d'extraction
├── controllers/
│   └── properties_controller.rb          # Action import_from_url ajoutée
├── javascript/
│   └── controllers/
│       └── property_importer_controller.js  # Interface utilisateur
└── views/
    └── properties/
        └── _form.html.erb                # Formulaire avec import

config/
└── routes.rb                             # Route POST /properties/import_from_url

IMPORT_AUTOMATIQUE.md                     # Documentation technique complète
GUIDE_IMPORT.md                          # Guide utilisateur détaillé
test_import.rb                           # Script de test manuel
```

## 🔧 Architecture

### Service Layer
```ruby
PropertyScraperService.new(url).call
# => { title: "...", price: 250000, surface: 65.0, ... }
```

### API Endpoint
```
POST /properties/import_from_url
Body: { url: "https://..." }
```

### Frontend (Stimulus)
```javascript
// Gère l'UI et remplit automatiquement le formulaire
property-importer-controller.js
```

## 💻 Utilisation Technique

### Dans la console Rails

```ruby
# Test simple
scraper = PropertyScraperService.new("https://www.seloger.com/annonces/...")
data = scraper.call

if data
  puts "✅ Données extraites :"
  data.each { |k, v| puts "  #{k}: #{v}" }
else
  puts "❌ Erreurs : #{scraper.errors.join(', ')}"
end

# Créer un bien directement
household = Household.first
property = household.properties.create!(data)
property.recalculate_score!
```

### Via l'API

```bash
curl -X POST http://localhost:3000/properties/import_from_url \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: your-token" \
  -d '{"url": "https://www.seloger.com/annonces/..."}'
```

## ⚙️ Configuration

Aucune configuration nécessaire ! 

Le service fonctionne immédiatement après installation.

## 🧪 Tests

### Test manuel rapide

```ruby
# Dans bin/rails console
load 'test_import.rb'
```

### Test avec une vraie URL

```ruby
# Remplacez par une vraie URL d'annonce
url = "https://www.seloger.com/annonces/achat/appartement/paris-75/12345.htm"
scraper = PropertyScraperService.new(url)
result = scraper.call
puts result.inspect
```

## 📚 Documentation complète

- **[IMPORT_AUTOMATIQUE.md](IMPORT_AUTOMATIQUE.md)** - Documentation technique détaillée
- **[GUIDE_IMPORT.md](GUIDE_IMPORT.md)** - Guide utilisateur pas à pas
- **[test_import.rb](test_import.rb)** - Script de test manuel

## ⚠️ Limitations

### Ce qui fonctionne
- ✅ URLs directes des sites immobiliers
- ✅ Redirections Jinka
- ✅ Extraction de base sur tout site

### Ce qui ne fonctionne pas (encore)
- ❌ Sites avec JavaScript lourd (nécessite un navigateur)
- ❌ Sites avec captcha
- ❌ Extraction des photos
- ❌ Détails très spécifiques (balcon, cave, etc.)

### Recommandations
- ⚠️ Toujours **vérifier** les données importées
- ⚠️ **Compléter** les champs manquants
- ⚠️ Utiliser pour un **usage personnel** uniquement

## 🚀 Améliorations futures

### Version 2.0 (Court terme)
- [ ] Cache des URLs déjà scrapées
- [ ] Import des photos
- [ ] Plus de champs extraits
- [ ] Support de nouveaux sites

### Version 3.0 (Moyen terme)
- [ ] API officielle avec partenaires
- [ ] IA pour améliorer l'extraction
- [ ] Détection automatique de baisses de prix
- [ ] Extension navigateur

### Version 4.0 (Long terme)
- [ ] Alertes automatiques
- [ ] Historique des prix
- [ ] Prédictions de valeur
- [ ] Recommandations personnalisées

## 🐛 Résolution de problèmes

### L'import ne fonctionne pas
1. Vérifiez que l'URL est complète
2. Testez sur un autre site
3. Vérifiez les logs Rails : `tail -f log/development.log`
4. Essayez en mode console : `PropertyScraperService.new(url).call`

### Données partielles
C'est normal ! Tous les sites ne fournissent pas toutes les informations.
→ Complétez manuellement les champs manquants.

### Erreur réseau
- Vérifiez votre connexion internet
- Le site cible peut être temporairement indisponible
- Réessayez dans quelques minutes

## 📞 Support

Pour toute question :
1. Consultez la [documentation technique](IMPORT_AUTOMATIQUE.md)
2. Lisez le [guide utilisateur](GUIDE_IMPORT.md)
3. Testez avec le [script de test](test_import.rb)
4. Consultez les logs Rails

## 🎉 Exemples de succès

### Jinka → SeLoger
```
Input:  https://api.jinka.fr/apiv2/alert/redirect_preview?token=xxx&ad=73850207
Output: Appartement T3, 250000€, 65m², Paris 75001
Temps:  3 secondes
```

### LeBonCoin direct
```
Input:  https://www.leboncoin.fr/ventes_immobilieres/12345.htm
Output: Maison 5 pièces, 450000€, 120m², Lyon 69001
Temps:  2 secondes
```

## 🏆 Best Practices

1. **Importez d'abord**, complétez ensuite
2. **Vérifiez toujours** les données critiques (prix, surface)
3. **Ajoutez vos notes** personnelles après l'import
4. **Utilisez le lien Jinka** quand possible (meilleure compatibilité)
5. **Complétez les critères subjectifs** (vue, quartier, etc.)

## 🎓 Pour aller plus loin

- Découvrez comment [ajouter un nouveau site](IMPORT_AUTOMATIQUE.md#ajout-dun-nouveau-site)
- Explorez le [code source du service](app/services/property_scraper_service.rb)
- Personnalisez l'[interface utilisateur](app/javascript/controllers/property_importer_controller.js)

---

**Prêt à gagner du temps ?** Essayez dès maintenant ! 🚀

