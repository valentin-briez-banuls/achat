source "https://rubygems.org"

gem "rails", "~> 8.1.2"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"

# Authentication & Authorization
gem "devise"
gem "pundit"

# Decorators
gem "draper"

# Charts
gem "chartkick"
gem "groupdate"

# Pagination
gem "pagy"

# Active Storage image processing
gem "image_processing", "~> 1.2"

# Web scraping & data extraction
gem "geocoder" # Géocoding automatique
gem "down", "~> 5.0" # Téléchargement d'images
gem "ferrum" # Browser automation pour JavaScript rendering

# Infrastructure
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false
gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "shoulda-matchers"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
  gem "letter_opener"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "database_cleaner-active_record"
  gem "pundit-matchers"
end
