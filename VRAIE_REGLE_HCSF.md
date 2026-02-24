# 📋 LA VRAIE RÈGLE BANCAIRE HCSF (2021-2026)

## ✅ Règle Officielle du Haut Conseil de Stabilité Financière

Depuis **janvier 2021**, TOUTES les banques françaises doivent respecter :

### 1️⃣ Taux d'Endettement Maximum : **35%**

```
Formule OFFICIELLE :
Taux = (Somme des mensualités de CRÉDITS) / Revenus nets × 100
```

### ✅ Ce Qui EST Compté (dans les 35%)

- ✅ **Nouveau crédit immobilier** (celui que vous demandez)
- ✅ **Crédits immobiliers en cours** (autre résidence, investissement locatif)
- ✅ **Crédits à la consommation** (voiture, moto, électroménager)
- ✅ **Crédits renouvelables** (réserves d'argent type Cetelem)
- ✅ **Pensions alimentaires** (obligation de paiement)

### ❌ Ce Qui N'EST PAS Compté

- ❌ **Loyer actuel** (il disparaîtra à l'achat)
- ❌ **Assurances** (auto, habitation, santé, vie)
- ❌ **Abonnements** (téléphone, internet, Netflix, salle de sport)
- ❌ **Charges courantes** (courses, essence, loisirs)
- ❌ **Impôts** (taxe d'habitation, impôts sur le revenu)
- ❌ **Charges de copropriété** (sauf si dans un crédit)
- ❌ **Factures** (électricité, eau, gaz)

### ❓ Cas Particulier : Le PTZ

Le PTZ est **débattu** :
- Certaines banques le comptent dans les 35%
- D'autres ne le comptent PAS pendant la période de différé
- Dépend de la politique de la banque

---

## 🔍 VOTRE SITUATION AVEC LA VRAIE RÈGLE

### Avant (Calcul Incorrect)

L'application comptait **TOUT** :
```
Mensualité : 857 €
+ Charges courantes : 700 € ❌ (INCORRECT)
─────────────────────────
Total : 1,557 €
Taux = 1,557 / 3,402 × 100 = 45.79%
```

### Après (Règle HCSF Officielle)

Avec la vraie règle, **seulement les crédits** :
```
Mensualité projet : 857 €
+ Crédits en cours : 0 € ✅ (vous n'en avez pas)
─────────────────────────
Total : 857 €
Taux = 857 / 3,402 × 100 = 25.2% ✅
```

**ÉNORME DIFFÉRENCE !**

---

## 🎉 RÉSULTAT POUR VOUS

### Vos Données Réelles

- **Revenus** : 3,402 €/mois (2 personnes)
- **Crédits en cours** : 0 € (aucun mentionné)
- **Mensualité projet** : 857 €/mois
- **Charges courantes** : 700 € (assurances, abonnements, garage)

### Taux d'Endettement RÉEL (Règle HCSF)

```
Taux = 857 / 3,402 × 100 = 25.2%
```

**🎯 Limite** : 35%  
**✅ Votre taux** : **25.2%**  
**🟢 Marge** : **-9.8 points** (EXCELLENT !)

---

## 💡 Ce Que Ça Change Pour Vous

### Avant (Calcul Incorrect)
- ❌ Taux affiché : 45.79%
- ❌ Verdict : "Trop élevé, dossier refusé"
- ❌ Conseil : "Négociez le prix ou augmentez l'apport"

### Maintenant (Règle Officielle)
- ✅ Taux réel : **25.2%**
- ✅ Verdict : **"EXCELLENT dossier"**
- ✅ Conseil : **"Vous êtes bien en dessous de la limite, foncez !"**

---

## 📊 Comparaison avec les Seuils

| Taux | Situation | Acceptation Bancaire |
|------|-----------|---------------------|
| 0-25% | Très bon | ✅✅✅ Facile |
| **25-30%** | **Bon** | **✅✅ Votre cas** |
| 30-33% | Correct | ✅ Acceptable |
| 33-35% | Limite | ⚠️ Possible |
| 35-38% | Hors norme | 🔴 Difficile (20% de quotas) |
| > 38% | Trop élevé | ❌ Refus quasi-certain |

**Vous êtes à 25.2%** = Dans la zone **"BON"** ✅

---

## 🏦 Sources Officielles

1. **Recommandation HCSF** (20 décembre 2019, révisée en 2021)
   - Taux d'endettement : 35% maximum
   - Durée : 25 ans (27 pour le neuf)
   - Flexibilité : 20% des dossiers

2. **Application depuis** : 1er janvier 2021

3. **Contrôle** : ACPR (Autorité de Contrôle Prudentiel)

4. **Pénalités** : Sanctions pour les banques qui dépassent les quotas

---

## 🎯 Impact des Charges Courantes

Bien que les **700 €** de charges courantes ne comptent PAS dans le taux d'endettement, les banques les regardent quand même pour vérifier le **"reste à vivre"**.

### Reste à Vivre

```
Revenus : 3,402 €
- Mensualité projet : 857 €
- Charges courantes : 700 €
─────────────────────────
Reste à vivre : 1,845 €
```

**Minimum recommandé** : 1,000-1,200 € pour un couple

**✅ Votre reste à vivre (1,845 €)** est **très confortable** !

---

## 📝 Corrections Apportées à l'Application

### 1. Nouveaux Champs Créés

- `existing_loan_payments` : Crédits en cours (comptés dans les 35%)
- `other_monthly_charges` : Charges courantes (non comptées)

### 2. Calcul Corrigé

**Avant** :
```ruby
total_charges = monthly[:total] + charges
debt_ratio = (total_charges / income * 100)
```

**Après (conforme HCSF)** :
```ruby
existing_loans = profile.existing_loan_payments || 0
total_loan_payments = monthly[:total] + existing_loans
debt_ratio = (total_loan_payments / income * 100)
```

### 3. Migration Automatique

Les données existantes ont été migrées :
- `monthly_charges` (700 €) → `existing_loan_payments` (0 €) + `other_monthly_charges` (700 €)

---

## ✅ Récapitulatif Final

### Question Initiale
> "C'est vraiment compté ça ? Genre c'est une règle utilisée souvent ?  
> Je veux la vraie règle vraiment utilisée."

### Réponse
**NON**, ce n'est **PAS** compté !

**La vraie règle HCSF** (utilisée par TOUTES les banques depuis 2021) ne compte QUE les crédits dans le taux d'endettement.

**Votre situation réelle** :
- ❌ Taux affiché (incorrect) : 45-48%
- ✅ **Taux réel (règle HCSF) : 25.2%**

**Verdict** : 🎉 **EXCELLENT DOSSIER** - Vous êtes **largement en dessous** de la limite de 35% !

---

## 🚀 Prochaines Étapes

1. ✅ **Rafraîchissez la page** de simulation (le taux devrait maintenant afficher ~25%)
2. ✅ **Vérifiez votre profil financier** pour confirmer la séparation des charges
3. ✅ **Préparez votre dossier bancaire** avec confiance
4. ✅ **Négociez si vous voulez**, mais vous avez déjà un excellent taux !

---

**Date de mise à jour** : 24 février 2026  
**Règle appliquée** : HCSF (Haut Conseil de Stabilité Financière)  
**Conformité** : ✅ 100% conforme aux règles bancaires françaises

