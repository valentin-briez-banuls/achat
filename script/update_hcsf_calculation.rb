#!/usr/bin/env ruby
# Script pour mettre à jour le profil financier avec la vraie règle HCSF

puts "=" * 80
puts "MISE À JOUR DU PROFIL FINANCIER - RÈGLE HCSF"
puts "=" * 80
puts

# Trouver le profil
household = Household.find_by(name: "Notre maison")
unless household
  puts "❌ Household 'Notre maison' non trouvé"
  exit 1
end

profile = household.financial_profile
unless profile
  puts "❌ Profil financier non trouvé"
  exit 1
end

puts "✅ Profil trouvé"
puts

# Afficher les valeurs actuelles
puts "VALEURS ACTUELLES :"
puts "  monthly_charges (ancien) : #{profile.monthly_charges} €"
puts "  existing_loan_payments : #{profile.existing_loan_payments || 'nil'} €"
puts "  other_monthly_charges : #{profile.other_monthly_charges || 'nil'} €"
puts

# Question : avez-vous des crédits en cours ?
puts "D'après la conversation :"
puts "  Vos 700€ de charges = assurances + abonnements + garage (250€)"
puts "  = PAS de crédits en cours mentionnés"
puts

# Mettre à jour
puts "MISE À JOUR :"
puts "  existing_loan_payments = 0 € (aucun crédit en cours)"
puts "  other_monthly_charges = 700 € (charges courantes)"

profile.update!(
  existing_loan_payments: 0,
  other_monthly_charges: 700
)

puts "  ✅ Profil mis à jour !"
puts

# Recalculer la simulation
simulation = Simulation.find(8)
puts "RECALCUL DE LA SIMULATION..."

old_taux = simulation.debt_ratio
simulation.recalculate!
new_taux = simulation.reload.debt_ratio

puts "  ✅ Simulation recalculée !"
puts

# Afficher les résultats
puts "=" * 80
puts "RÉSULTATS"
puts "=" * 80
puts

puts "CALCUL DU TAUX (RÈGLE HCSF) :"
puts "  Mensualité projet : #{simulation.total_monthly_payment} €"
puts "  Crédits en cours : 0 €"
puts "  ───────────────────────────"
puts "  Total crédits : #{simulation.total_monthly_payment} €"
puts "  Revenus : #{profile.total_monthly_income} €"
puts

puts "TAUX D'ENDETTEMENT :"
puts "  Ancien taux (incorrect) : #{old_taux}%"
puts "  Nouveau taux (HCSF) : #{new_taux}%"
puts "  Différence : #{(old_taux - new_taux).round(2)} points"
puts

if new_taux <= 33
  puts "✅ EXCELLENT : Taux très bon (< 33%)"
elsif new_taux <= 35
  puts "✅ BON : Taux acceptable (< 35%)"
elsif new_taux <= 38
  puts "🟡 LIMITE : Taux élevé mais faisable (< 38%)"
else
  puts "🔴 PROBLÈME : Taux trop élevé (> 38%)"
end

puts
puts "NOTE : Les 700€ de charges courantes (assurances, abonnements)"
puts "ne sont PAS comptés dans le taux selon la règle HCSF."
puts
puts "=" * 80

