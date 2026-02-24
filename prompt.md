🔥 CONTEXTE

Tu es un développeur senior Ruby on Rails expert en architecture, finance immobilière et UX.

Je veux que tu génères un projet Ruby on Rails complet (Rails 7 ou 8), proprement structuré, avec :

PostgreSQL

Hotwire (Turbo + Stimulus)

TailwindCSS

Devise pour authentification

RSpec pour tests

Services objects pour la logique métier financière

Architecture propre, scalable

L’application doit être conçue comme un vrai SaaS personnel robuste.

🧠 FONCTIONNALITÉS ATTENDUES
1️⃣ Gestion des utilisateurs

Authentification (Devise)

Un couple = 2 utilisateurs liés à un "Household"

Un household contient :

Revenus

Dépenses

Apport

Situation fiscale

Zone PTZ

2️⃣ Module Profil Financier
Données à stocker :

Salaire net mensuel personne 1

Salaire net mensuel personne 2

Autres revenus

Charges mensuelles fixes

Apport disponible

Épargne restante après apport

Type de contrat (CDI, CDD, freelance)

Taux actuel proposé

Durée souhaitée (15, 20, 25 ans)

Calculs automatiques :

Capacité d’emprunt

Taux d’endettement

Mensualité max

Reste à vivre

Créer un FinancialProfileCalculator service object.

3️⃣ Gestion des critères immobiliers
Critères obligatoires :

Budget max

Surface minimum

Nombre de chambres

Extérieur obligatoire (bool)

Parking obligatoire (bool)

Distance max travail

Zone géographique

Ancien / Neuf

Classe énergétique minimum

Critères pondérés (score) :

Quartier

Vue

Exposition

Travaux à prévoir

Calme

Luminosité

Créer un système de scoring automatique :

Score /100

Correspondance stricte

Correspondance partielle

Non compatible

Créer un PropertyMatcher service object.

4️⃣ Module Biens Immobiliers

Chaque bien doit contenir :

Prix affiché

Surface

Type

Ville

Code postal

Frais d’agence

Estimation frais de notaire

DPE

Charges copro

Taxe foncière

Travaux estimés

Lien annonce

Photos

Notes personnelles

Statut :

À analyser

À visiter

Visité

Offre faite

Refusé

Accepté

5️⃣ Calculs financiers par bien

Créer un PropertyFinanceSimulator service object.

Pour chaque bien calculer :

Frais de notaire (7-8% ancien, 2-3% neuf)

Frais d’agence si inclus

Coût total projet

PTZ éligibilité

Montant PTZ

Montant prêt principal

Mensualité totale

Coût total crédit

Effort mensuel réel

6️⃣ Calcul PTZ

Créer un PTZCalculator service object prenant en compte :

Zone (A, A bis, B1, B2, C)

Nombre de personnes

Revenus fiscaux

Type de bien

Plafonds réglementaires

Il doit :

Vérifier l’éligibilité

Calculer le montant maximum

Intégrer le différé

7️⃣ Dashboard principal

Vue synthétique avec :

Capacité d’emprunt

Budget optimal

Liste des biens classés par score

Graphique comparatif des mensualités

Graphique impact sur taux d’endettement

Indicateur feu vert / orange / rouge

8️⃣ Comparateur de biens

Pouvoir sélectionner 2 à 4 biens et afficher :

Tableau comparatif

Score

Coût total

Mensualité

Rentabilité (si investissement)

Points forts / faibles

9️⃣ Simulation avancée

Permettre de :

Modifier taux

Modifier durée

Ajouter travaux

Simuler négociation prix (-5%, -10%)

🔟 Roadmap future

Prévoir architecture pour :

API d’estimation bancaire

Scraping automatique SeLoger / Leboncoin

Alertes email

Export PDF dossier bancaire

Mode investisseur locatif

🏗️ STRUCTURE TECHNIQUE ATTENDUE
Modèles :

User

Household

FinancialProfile

Property

PropertyScore

Simulation

Visit

Offer

Service Objects :

FinancialProfileCalculator

PropertyMatcher

PropertyFinanceSimulator

PTZCalculator

NotaryFeeCalculator

LoanCalculator

Architecture :

Fat services, skinny controllers

Decorators pour affichage

Form objects si nécessaire

Policies Pundit

Background jobs si utile

📊 UX/UI

Interface moderne

Dashboard clair

Indicateurs visuels

Graphiques

Badges de compatibilité

Responsive

🧮 Formules à intégrer

Taux d’endettement = mensualités / revenus

Mensualité crédit = formule amortissement classique

PTZ plafonds selon zone

Frais notaire ancien vs neuf

Frais agence inclus / exclus

📦 CE QUE JE VEUX QUE TU GÉNÈRES

Arborescence complète du projet

Migrations

Modèles avec validations

Service objects détaillés

Controllers

Routes

Vues principales

Seeds de test réalistes

Exemples de tests RSpec

README détaillé

🎯 BONUS

Ajoute :

Système de scoring intelligent basé sur pondération dynamique

Graphique d’évolution si taux augmente

Simulation inflation

Mode pessimiste / optimiste

Indicateur “danger financier”

Heatmap des villes analysées

🧠 EXIGENCE

Le code doit être :

Professionnel

Maintenable

Bien commenté

Structuré comme un vrai projet SaaS

Prêt à être déployé

Ne me donne pas juste un squelette.
Donne-moi une vraie base exploitable.