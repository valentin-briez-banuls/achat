FactoryBot.define do
  factory :property do
    household
    title { "#{Faker::Address.community} - T#{rand(2..5)}" }
    price { rand(150_000..400_000) }
    surface { rand(40..120).to_f }
    property_type { :appartement }
    rooms { rand(2..5) }
    bedrooms { rand(1..3) }
    city { Faker::Address.city }
    postal_code { format("%05d", rand(1000..95999)) }
    condition { :ancien }
    agency_fees { rand(5000..15000) }
    agency_fees_included { true }
    copro_charges_monthly { rand(100..400) }
    property_tax_yearly { rand(500..2000) }
    estimated_works { rand(0..30000) }
    energy_class { %w[A B C D E F G].sample }
    has_outdoor { [true, false].sample }
    has_parking { [true, false].sample }
    status { :a_analyser }

    trait :with_scores do
      score_neighborhood { rand(1..5) }
      score_view { rand(1..5) }
      score_orientation { rand(1..5) }
      score_renovation { rand(1..5) }
      score_quietness { rand(1..5) }
      score_brightness { rand(1..5) }
    end

    trait :neuf do
      condition { :neuf }
    end
  end
end
