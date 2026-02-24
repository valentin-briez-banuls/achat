puts "Nettoyage de la base..."
[Offer, Visit, Simulation, PropertyScore, Property, PropertyCriterion, FinancialProfile, User, Household].each(&:destroy_all)

puts "Création du foyer..."
household = Household.create!(name: "Foyer Dupont-Martin")

puts "Création des utilisateurs..."
user1 = User.create!(
  email: "jean@example.com",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Jean",
  last_name: "Dupont",
  household: household
)

user2 = User.create!(
  email: "marie@example.com",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Marie",
  last_name: "Martin",
  household: household
)

puts "Création du profil financier..."
profile = FinancialProfile.create!(
  household: household,
  salary_person_1: 2_800,
  salary_person_2: 2_200,
  other_income: 150,
  monthly_charges: 450,
  personal_contribution: 35_000,
  remaining_savings: 12_000,
  contract_type_person_1: :cdi_1,
  contract_type_person_2: :cdi_2,
  proposed_rate: 3.45,
  desired_duration_years: 25,
  fiscal_reference_income: 48_000,
  household_size: 2,
  ptz_zone: "B1"
)
profile.recalculate!
puts "  -> Capacité d'emprunt : #{profile.borrowing_capacity}€"
puts "  -> Mensualité max : #{profile.max_monthly_payment}€"

puts "Création des critères de recherche..."
criteria = PropertyCriterion.create!(
  household: household,
  max_budget: 280_000,
  min_surface: 55,
  min_bedrooms: 2,
  outdoor_required: true,
  parking_required: false,
  max_work_distance_km: 20,
  geographic_zone: "Lyon",
  property_condition: :any_condition,
  min_energy_class: "D",
  weight_neighborhood: 8,
  weight_view: 5,
  weight_orientation: 6,
  weight_renovation: 7,
  weight_quietness: 8,
  weight_brightness: 6
)

puts "Création des biens immobiliers..."
properties_data = [
  {
    title: "T3 lumineux Croix-Rousse",
    price: 265_000, surface: 62, property_type: :appartement, rooms: 3, bedrooms: 2,
    city: "Lyon", postal_code: "69004", condition: :ancien,
    agency_fees: 8_000, agency_fees_included: true,
    copro_charges_monthly: 180, property_tax_yearly: 850, estimated_works: 5_000,
    energy_class: "C", ges_class: "C", has_outdoor: true, has_parking: false,
    floor: 4, total_floors: 6,
    score_neighborhood: 5, score_view: 4, score_orientation: 4,
    score_renovation: 3, score_quietness: 3, score_brightness: 5,
    status: :a_visiter,
    listing_url: "https://www.seloger.com/example-1",
    personal_notes: "Très bel appartement avec vue sur les toits. Travaux salle de bain à prévoir."
  },
  {
    title: "T4 avec terrasse Villeurbanne",
    price: 245_000, surface: 78, property_type: :appartement, rooms: 4, bedrooms: 3,
    city: "Villeurbanne", postal_code: "69100", condition: :ancien,
    agency_fees: 7_500, agency_fees_included: true,
    copro_charges_monthly: 220, property_tax_yearly: 950, estimated_works: 15_000,
    energy_class: "D", ges_class: "D", has_outdoor: true, has_parking: true,
    floor: 2, total_floors: 5,
    score_neighborhood: 3, score_view: 3, score_orientation: 4,
    score_renovation: 2, score_quietness: 4, score_brightness: 4,
    status: :visite,
    personal_notes: "Bon potentiel mais gros travaux cuisine et salle de bain."
  },
  {
    title: "T3 neuf Part-Dieu",
    price: 310_000, surface: 58, property_type: :appartement, rooms: 3, bedrooms: 2,
    city: "Lyon", postal_code: "69003", condition: :neuf,
    agency_fees: 0, agency_fees_included: true,
    copro_charges_monthly: 150, property_tax_yearly: 0, estimated_works: 0,
    energy_class: "A", ges_class: "A", has_outdoor: true, has_parking: true,
    floor: 7, total_floors: 12,
    score_neighborhood: 3, score_view: 5, score_orientation: 5,
    score_renovation: 5, score_quietness: 2, score_brightness: 5,
    status: :a_analyser,
    personal_notes: "Programme neuf livraison T4 2026. Vue panoramique."
  },
  {
    title: "Maison de ville Tassin",
    price: 350_000, surface: 95, property_type: :maison, rooms: 5, bedrooms: 3,
    city: "Tassin-la-Demi-Lune", postal_code: "69160", condition: :ancien,
    agency_fees: 12_000, agency_fees_included: false,
    copro_charges_monthly: 0, property_tax_yearly: 1_400, estimated_works: 25_000,
    energy_class: "E", ges_class: "E", has_outdoor: true, has_parking: true,
    floor: nil, total_floors: 2,
    score_neighborhood: 4, score_view: 3, score_orientation: 3,
    score_renovation: 1, score_quietness: 5, score_brightness: 3,
    status: :offre_faite,
    personal_notes: "Coup de coeur malgré les travaux. Jardin de 150m². Quartier calme."
  },
  {
    title: "Studio investissement Gerland",
    price: 135_000, surface: 28, property_type: :appartement, rooms: 1, bedrooms: 0,
    city: "Lyon", postal_code: "69007", condition: :ancien,
    agency_fees: 5_000, agency_fees_included: true,
    copro_charges_monthly: 80, property_tax_yearly: 400, estimated_works: 3_000,
    energy_class: "D", ges_class: "C", has_outdoor: false, has_parking: false,
    floor: 3, total_floors: 5,
    score_neighborhood: 3, score_view: 2, score_orientation: 3,
    score_renovation: 3, score_quietness: 3, score_brightness: 3,
    status: :refuse,
    personal_notes: "Trop petit pour nous. Gardé pour investissement locatif potentiel."
  }
]

properties_data.each do |data|
  property = Property.create!(data.merge(household: household))
  property.recalculate_score!

  # Create default simulation
  sim = property.simulations.create!(
    name: "Simulation initiale",
    scenario: :standard,
    loan_rate: profile.proposed_rate,
    loan_duration_years: profile.desired_duration_years,
    personal_contribution: profile.personal_contribution,
    negotiated_price: property.price
  )
  sim.recalculate!

  puts "  -> #{property.title}: score #{property.property_score&.total_score}/100, mensualité #{sim.total_monthly_payment}€"
end

# Simulation supplémentaire optimiste pour le T3 Croix-Rousse
croix_rousse = Property.find_by(title: "T3 lumineux Croix-Rousse")
if croix_rousse
  sim_opti = croix_rousse.simulations.create!(
    name: "Négociation -5%",
    scenario: :optimiste,
    loan_rate: 3.2,
    loan_duration_years: 25,
    personal_contribution: 35_000,
    negotiated_price: croix_rousse.price * 0.95,
    price_negotiation_percent: 5
  )
  sim_opti.recalculate!

  sim_pessi = croix_rousse.simulations.create!(
    name: "Scénario pessimiste taux 4.5%",
    scenario: :pessimiste,
    loan_rate: 4.5,
    loan_duration_years: 20,
    personal_contribution: 35_000,
    negotiated_price: croix_rousse.price
  )
  sim_pessi.recalculate!
end

# Visites
villeurbanne = Property.find_by(title: "T4 avec terrasse Villeurbanne")
if villeurbanne
  Visit.create!(property: villeurbanne, user: user1, scheduled_at: 2.days.ago, status: :effectuee, verdict: :positif,
                notes: "Bel espace, bien agencé", pros: "Surface, terrasse, parking", cons: "Travaux importants, vis-à-vis côté salon")
  Visit.create!(property: villeurbanne, user: user2, scheduled_at: 2.days.ago, status: :effectuee, verdict: :neutre,
                notes: "À revoir pour confirmer", pros: "Quartier sympa", cons: "Budget travaux incertain")
end

tassin = Property.find_by(title: "Maison de ville Tassin")
if tassin
  Visit.create!(property: tassin, user: user1, scheduled_at: 5.days.ago, status: :effectuee, verdict: :coup_de_coeur,
                notes: "Magnifique jardin, quartier très calme", pros: "Jardin, calme, espace", cons: "Travaux 25k€, un peu excentré")
  Offer.create!(property: tassin, amount: 335_000, offered_on: 3.days.ago,
                response_deadline: 4.days.from_now, status: :en_attente,
                conditions: "Sous réserve d'obtention du prêt", notes: "Offre à -4.3% du prix affiché")
end

if croix_rousse
  Visit.create!(property: croix_rousse, user: user1, scheduled_at: 3.days.from_now, status: :planifiee, notes: "Première visite prévue samedi 14h")
end

puts ""
puts "Seeds terminés !"
puts "================================"
puts "Connexion : jean@example.com / password123"
puts "           marie@example.com / password123"
puts "================================"
