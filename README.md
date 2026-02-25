# 🏠 Achat - Plateforme d'Aide à l'Achat Immobilier

**Achat** est une application Rails complète conçue pour accompagner les couples et acheteurs immobiliers dans l'analyse, la comparaison et la négociation de biens immobiliers. Elle intègre des calculateurs financiers avancés, un système de scoring intelligent, des simulations de prêt et des outils de suivi de biens.

---

## 🎯 Fonctionnalités Principales

### 👥 Gestion des Foyers (Households)
- **Authentification** via Devise
- **Foyers collaboratifs** : un couple = 2 utilisateurs liés à un même Household
- **Invitations sécurisées** par token unique
- **Gestion du profil financier commun**

### 💰 Profil Financier
- Revenus individuels et communs (salaires, autres revenus)
- Charges mensuelles et crédits en cours
- Apport personnel et épargne restante
- Type de contrat (CDI, CDD, Freelance, Fonctionnaire)
- **Calculs automatiques** :
  - Capacité d'emprunt maximale
  - Taux d'endettement (HCSF compliant)
  - Mensualité maximale
  - Reste à vivre
- **Éligibilité PTZ** selon zone, revenus et nombre de personnes

### 🏡 Gestion des Biens Immobiliers
- **Import automatique** depuis URL (scraping intelligent avec JavaScript rendering)
- **Extraction automatique** des données : prix, surface, photos, DPE, localisation
- **Suivi de l'historique des prix** avec détection des baisses
- **Gestion des photos** via Active Storage
- **Statuts de suivi** : À analyser → À visiter → Visité → Offre faite → Refusé/Accepté

### 🎯 Système de Scoring Intelligent
- **Critères pondérés** configurables par le foyer :
  - Quartier, Vue, Orientation, Luminosité, Calme
  - État de rénovation, Proximité transports
- **Scoring automatique** /100 pour chaque bien
- **Comparateur visuel** de plusieurs biens côte à côte

### 💡 Simulateur de Négociation
- **Calculs en temps réel** de l'impact d'une remise (-3%, -5%, -8%...)
- **Visualisation instantanée** :
  - Nouvelle mensualité
  - Nouveau taux d'endettement
  - Coût total du crédit
  - Frais de notaire ajustés
- **Création d'offre pré-remplie** avec le montant négocié

### 🔧 Estimation des Travaux
- **Items de rénovation** par bien avec fourchettes de coûts
- **Calcul automatique** du coût total projet :
  - Prix d'achat + Frais de notaire + Travaux estimés

### 📊 Simulations de Prêt
- **Calculateur de prêt avancé** (formule d'amortissement classique)
- **PTZ Calculator** intégré avec plafonds réglementaires
- **Tableaux d'amortissement** complets
- **Graphiques interactifs** (Chartkick + Groupdate)

### 📝 Suivi des Visites et Offres
- **Checklist de visite** avec notes et impressions
- **Gestion des offres** avec statuts (En attente, Acceptée, Refusée, Retirée)
- **Historique complet** des actions sur chaque bien

### 📈 Dashboard Analytique
- Vue synthétique du budget et de la capacité d'emprunt
- Liste des biens classés par score
- Indicateurs visuels (feu vert/orange/rouge)
- Comparaison rapide des biens favoris

---

## 🛠️ Stack Technique

### Backend
- **Ruby on Rails** 8.1.2
- **PostgreSQL** 16+ (avec schémas Solid pour cache/queue/cable)
- **Devise** pour l'authentification
- **Pundit** pour les autorisations

### Frontend
- **Hotwire** (Turbo + Stimulus)
- **TailwindCSS** pour le design
- **Chartkick** pour les graphiques
- **Importmap** (pas de bundler JS)

### Infrastructure
- **Solid Cache** (cache en base de données)
- **Solid Queue** (jobs en arrière-plan)
- **Solid Cable** (WebSockets)
- **Puma** comme serveur web
- **Docker** + Docker Compose pour le déploiement
- **Kamal** pour l'orchestration en production

### Services Métier
- `FinancialProfileCalculator` : calculs de capacité d'emprunt
- `LoanCalculator` : simulations de crédit
- `PTZCalculator` : éligibilité et montant PTZ
- `NotaryFeeCalculator` : frais de notaire selon type de bien
- `PropertyMatcher` : scoring et compatibilité
- `PropertyScraperService` : extraction de données depuis URLs
- `JavascriptRendererService` : rendu de pages JavaScript (Ferrum)

### Testing
- **RSpec** pour les tests
- **FactoryBot** pour les fixtures
- **Faker** pour les données de test
- **Shoulda Matchers** pour les validations
- **Capybara** + **Selenium** pour les tests E2E
- **Pundit Matchers** pour tester les policies

---

## 📋 Prérequis

- **Ruby** 3.3+ (vérifier avec `ruby -v`)
- **PostgreSQL** 16+
- **Node.js** (pour Tailwind CSS)
- **Chrome/Chromium** (pour le scraping JavaScript avec Ferrum)

---

## 🚀 Installation

### 1. Cloner le dépôt

```bash
git clone <repository-url>
cd achat
```

### 2. Installer les dépendances

```bash
bundle install
```

### 3. Configurer la base de données

Créer un fichier `.env` ou configurer `config/database.yml` si nécessaire :

```bash
# Créer les bases de données
bin/rails db:create

# Exécuter les migrations
bin/rails db:migrate

# Charger les données de test (optionnel)
bin/rails db:seed
```

### 4. Lancer le serveur de développement

```bash
# Avec Foreman (recommandé, lance Rails + Tailwind CSS)
bin/dev

# Ou manuellement
bin/rails server
```

L'application sera accessible sur **http://localhost:3000**

---

## 🧪 Tests

### Lancer la suite de tests

```bash
# Tous les tests
bundle exec rspec

# Un fichier spécifique
bundle exec rspec spec/models/property_spec.rb

# Tests de services
bundle exec rspec spec/services
```

### Linters et analyseurs de sécurité

```bash
# Rubocop (style de code)
bin/rubocop

# Brakeman (sécurité)
bin/brakeman

# Bundler Audit (CVEs dans les gems)
bin/bundler-audit
```

---

## 🐳 Déploiement avec Docker

### Développement local

```bash
docker-compose up -d
```

### Production

L'application utilise **Kamal** pour le déploiement :

```bash
# Premier déploiement
kamal setup

# Déploiements suivants
kamal deploy

# Voir les logs
kamal logs
```

Configuration dans `config/deploy.yml`.

---

## 📁 Structure du Projet

```
app/
├── controllers/       # Contrôleurs Rails (Dashboard, Properties, Offers, etc.)
├── models/            # Modèles ActiveRecord (Property, Household, FinancialProfile...)
├── services/          # Logique métier (Calculateurs financiers, scraping)
├── policies/          # Autorisations Pundit
├── decorators/        # Draper decorators pour la présentation
├── forms/             # Form Objects pour les formulaires complexes
├── views/             # Templates ERB + Turbo Frames
├── javascript/        # Contrôleurs Stimulus
└── assets/            # Stylesheets Tailwind, images

config/
├── routes.rb          # Routes de l'application
├── database.yml       # Configuration PostgreSQL
└── initializers/      # Configuration Devise, Pundit, etc.

db/
├── migrate/           # Migrations ActiveRecord
└── schema.rb          # Schéma actuel de la base

spec/                  # Tests RSpec
features/              # Documentation des fonctionnalités (10 features planifiées)
```

---

## 🗺️ Routes Principales

| Route | Description |
|-------|-------------|
| `GET /` | Redirection vers `/dashboard` si connecté, sinon `/users/sign_in` |
| `GET /dashboard` | Vue d'ensemble : biens, budget, statistiques |
| `GET /household` | Profil du foyer |
| `GET /financial_profile` | Profil financier (revenus, charges, apport) |
| `GET /property_criterion` | Critères de recherche et pondérations |
| `GET /properties` | Liste des biens |
| `POST /properties/import_from_url` | Import automatique depuis URL |
| `GET /properties/:id` | Détail d'un bien |
| `GET /properties/:id/negotiation` | Simulateur de négociation |
| `GET /properties/:id/simulations/new` | Nouvelle simulation de prêt |
| `GET /properties/:id/offers` | Offres faites sur le bien |
| `GET /comparison` | Comparateur de biens |

---

## 🔑 Variables d'Environnement

Créer un fichier `.env` à la racine :

```bash
# Base de données
DATABASE_URL=postgresql://user:password@localhost/achat_development

# Devise
DEVISE_SECRET_KEY=your_secret_key_here

# Rails
RAILS_ENV=development
SECRET_KEY_BASE=your_secret_key_base

# Scraping (optionnel)
CHROME_NO_SANDBOX=true  # Pour Docker/CI
```

---

## 🎨 Personnalisation

### Modifier les pondérations de scoring

Dans `PropertyCriterion`, ajuster les poids des critères (0-10) :

```ruby
# app/models/property_criterion.rb
validates :weight_neighborhood, numericality: { in: 0..10 }
```

### Ajouter de nouveaux calculateurs

Créer un service dans `app/services/` :

```ruby
class MyCalculator
  def initialize(param:)
    @param = param
  end

  def call
    # Logique métier
  end
end
```

### Ajouter des scraper pour de nouveaux sites

Étendre `PropertyScraperService` avec de nouveaux patterns :

```ruby
# app/services/property_scraper_service.rb
def detect_site(url)
  case url
  when /nouveausite\.fr/
    extract_nouveausite(url)
  end
end
```

---

## 📚 Documentation des Fonctionnalités

10 fonctionnalités avancées sont documentées dans `/features` :

1. **Negotiation Simulator** - Simulateur de négociation avec sliders
2. **Price History Alerts** - Alertes sur les baisses de prix
3. **Renovation Cost Estimator** - Estimateur de travaux
4. **Scoring Criteria Weights Editor** - Éditeur de pondérations
5. **Public Share Link** - Partage sécurisé de biens
6. **Visit Checklist** - Checklist de visite structurée
7. **Neighbourhood Map** - Carte interactive du quartier
8. **PDF Report Export** - Export PDF des analyses
9. **Loan Rate Tracker** - Suivi des taux d'emprunt
10. **Email Digests** - Résumés hebdomadaires par email

Consultez chaque fichier `.md` pour les spécifications détaillées.

---

## 🤝 Contribution

1. Fork le projet
2. Créer une branche (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

### Standards de code

- Suivre les conventions **Rubocop Rails Omakase**
- Tests obligatoires pour toute nouvelle fonctionnalité
- Messages de commit explicites

---

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

---

## 🙏 Remerciements

- **Rails 8** pour la stack moderne (Solid Queue, Solid Cache, Solid Cable)
- **Hotwire** pour la réactivité sans complexité JavaScript
- **TailwindCSS** pour un design rapide et maintenable
- La communauté Ruby/Rails pour les gems indispensables

---

## 📞 Support

Pour toute question ou problème :

- Ouvrir une **Issue** sur GitHub
- Consulter la documentation dans `/features`
- Vérifier les logs : `tail -f log/development.log`

---

**Happy House Hunting! 🏡✨**
