source "https://rubygems.org"

ruby "~> 3.3"

gem "rails", "~> 8.1.3"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "sprockets-rails"
gem "jbuilder"
gem "redis", ">= 4.0.1"
gem "bcrypt", "~> 3.1.7"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", require: false
gem "image_processing", "~> 1.2"

# Auth
gem "devise"
gem "omniauth"
gem "omniauth-google-oauth2"
gem "omniauth-facebook"
gem "omniauth-rails_csrf_protection"

# Background jobs
gem "sidekiq"
gem "connection_pool", "~> 2.4"

# Video processing
gem "streamio-ffmpeg"

# HTTP client
gem "faraday"
gem "faraday-multipart"

# File uploads validation
gem "active_storage_validations"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]
  gem "dotenv-rails"
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
