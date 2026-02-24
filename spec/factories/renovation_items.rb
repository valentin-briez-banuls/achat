FactoryBot.define do
  factory :renovation_item do
    property
    category { :cuisine }
    description { "Cuisine à refaire" }
    estimated_cost_min { 5_000 }
    estimated_cost_max { 15_000 }

    trait :sols do
      category { :sols }
      description { "Parquet à poser" }
      estimated_cost_min { 2_500 }
      estimated_cost_max { 6_000 }
    end

    trait :isolation do
      category { :isolation }
      description { "Isolation des combles" }
      estimated_cost_min { 3_000 }
      estimated_cost_max { 8_000 }
    end

    trait :fenetres do
      category { :fenetres }
      description { "Remplacement des fenêtres" }
      estimated_cost_min { 4_000 }
      estimated_cost_max { 10_000 }
    end
  end
end
