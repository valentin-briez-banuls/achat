FactoryBot.define do
  factory :property_price_history do
    property
    price { rand(150_000..400_000) }
    scraped_at { Time.current }
    source { "manual" }
  end
end
