FactoryBot.define do
  factory :simulation do
    property
    name { "Simulation test" }
    scenario { :standard }
    loan_rate { 3.5 }
    loan_duration_years { 25 }
    personal_contribution { 30_000 }
    negotiated_price { 250_000 }
    additional_works { 0 }
    price_negotiation_percent { 0 }
  end
end
