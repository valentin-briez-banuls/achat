# Amélioration de l'import automatique des propriétés

## 📋 Résumé des modifications

### 1. ✅ Correction du bug "Missing target element 'form'"
**Fichier** : `app/views/properties/_form.html.erb`

**Problème** : La cible Stimulus `form` était définie sur une `<div>` wrapper au lieu de l'élément `<form>` réel, empêchant le contrôleur JavaScript de trouver les inputs du formulaire.

**Solution** : Déplacé `data-property-importer-target="form"` vers l'élément `<form>` généré par `form_with`.

### 2. ✅ Gestion des URLs en format Markdown
**Fichier** : `app/controllers/properties_controller.rb`

**Problème** : Les URLs copiées depuis certaines sources (ex: emails, documents) contiennent du formatage Markdown comme `[url](url)`, causant une erreur 422.

**Solution** : Ajout d'une méthode `clean_url` qui :
- Nettoie les liens Markdown : `[texte](url)` → `url`
- Nettoie les liens entre chevrons : `<url>` → `url`
- Décode les URLs encodées
- Supprime les espaces

### 3. ✅ Extraction améliorée des données
**Fichier** : `app/services/property_scraper_service.rb`

**Problème** : L'extraction générique ne récupérait que le titre, le prix et la surface. Les informations importantes comme la ville, le nombre de pièces et chambres n'étaient pas extraites.

**Solution** : Améliorations apportées :

#### Nouvelles méthodes d'extraction :
- `extract_generic_bedrooms(html)` - Extrait le nombre de chambres
- `extract_generic_postal_code(html)` - Extrait le code postal
- `extract_generic_type(html)` - Détermine le type de bien
- `parse_title_info(title)` - Parse les titres structurés (ex: Jinka)

#### Méthode `parse_title_info` :
Parse les formats de titre comme : **"Alenya - 169000€ - 100m - 4p. - 3ch. - via une agence"**

Extrait :
- Ville
- Prix (si présent dans le titre)
- Surface
- Nombre de pièces
- Nombre de chambres

### 4. ✅ Amélioration du logging
**Fichier** : `app/controllers/properties_controller.rb`

Ajout de logs pour faciliter le débogage :
- URL reçue et URL nettoyée
- Résultat du scraping
- Erreurs détaillées

## 📊 Données maintenant extraites

Pour une URL Jinka typique, le système extrait maintenant :

| Champ | Exemple | Source |
|-------|---------|--------|
| **Titre** | "Alenya - 169000€ - 100m - 4p. - 3ch." | HTML/Titre |
| **Prix** | 169 000 € | Titre ou HTML |
| **Surface** | 100 m² | Titre ou HTML |
| **Pièces** | 4 | Titre ou HTML |
| **Chambres** | 3 | Titre ou HTML |
| **Ville** | Alenya | Titre ou HTML |
| **Code postal** | (si disponible) | HTML |
| **Type de bien** | (si disponible) | HTML |
| **DPE** | (si disponible) | HTML |
| **URL de l'annonce** | URL originale | Paramètre |

## 🧪 Tests

### Test manuel via l'interface :
1. Aller sur : http://localhost:3000/properties/new
2. Coller une URL dans le champ d'import (même en format Markdown)
3. Cliquer sur "Importer depuis l'URL"
4. Le formulaire se remplit automatiquement

### Test via la page de test :
http://localhost:3000/test_import.html

### Test en ligne de commande :
```bash
bin/rails runner "
url = 'https://api.jinka.fr/apiv2/alert/redirect_preview?token=XXX&ad=XXX'
scraper = PropertyScraperService.new(url)
result = scraper.call
pp result
"
```

## 🎯 Prochaines améliorations possibles

1. **Suivre les redirections JavaScript** : Pour extraire encore plus de données depuis la page finale
2. **Géocoding automatique** : Convertir ville + code postal en latitude/longitude
3. **Extraction d'images** : Télécharger automatiquement les photos de l'annonce
4. **Cache des extractions** : Éviter de re-scraper la même URL plusieurs fois
5. **Support d'autres plateformes** : Ajouter le support natif pour plus de sites immobiliers

## 🐛 Débogage

Si l'import ne fonctionne pas :

1. **Vérifier les logs** :
   ```bash
   tail -f log/development.log | grep PropertyScraperService
   ```

2. **Tester le service directement** :
   ```bash
   bin/rails runner "
   scraper = PropertyScraperService.new('URL_ICI')
   result = scraper.call
   puts result.inspect
   puts scraper.errors.inspect
   "
   ```

3. **Vérifier le token CSRF** : Ouvrir la console du navigateur et vérifier qu'il n'y a pas d'erreur 422 ou CSRF

## 📝 Notes techniques

- Le service gère automatiquement les redirections Jinka
- Les URLs en format Markdown sont automatiquement nettoyées
- Le parsing du titre est fait en priorité sur l'extraction HTML pour les sites comme Jinka
- Les données non trouvées ne bloquent pas l'import (champs optionnels)

