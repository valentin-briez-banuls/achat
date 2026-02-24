FactoryBot.define do
  factory :household do
    name { "Foyer #{Faker::Name.last_name}" }
  end
end
