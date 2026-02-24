FactoryBot.define do
  factory :property_criterion do
    household
    max_budget { 300_000 }
    min_surface { 60 }
    min_bedrooms { 2 }
    outdoor_required { true }
    parking_required { false }
    max_work_distance_km { 15 }
    geographic_zone { "Lyon" }
    property_condition { :any_condition }
    min_energy_class { "D" }
    weight_neighborhood { 7 }
    weight_view { 5 }
    weight_orientation { 6 }
    weight_renovation { 8 }
    weight_quietness { 7 }
    weight_brightness { 6 }
  end
end
