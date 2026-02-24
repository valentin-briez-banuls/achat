FactoryBot.define do
  factory :financial_profile do
    household
    salary_person_1 { 2800 }
    salary_person_2 { 2200 }
    other_income { 0 }
    monthly_charges { 500 }
    personal_contribution { 30_000 }
    remaining_savings { 10_000 }
    contract_type_person_1 { :cdi_1 }
    contract_type_person_2 { :cdi_2 }
    proposed_rate { 3.5 }
    desired_duration_years { 25 }
    fiscal_reference_income { 48_000 }
    household_size { 2 }
    ptz_zone { "B1" }
  end
end
