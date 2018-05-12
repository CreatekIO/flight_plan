source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.1.4'

gem 'mysql2', '>= 0.3.18', '< 0.5'
gem 'puma', '~> 3.7'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'webpacker'

gem 'coffee-rails', '~> 4.2'
gem 'jbuilder', '~> 2.5'
gem 'turbolinks', '~> 5'

gem 'bootstrap-sass'
gem 'business_time'
gem 'cancancan', '~> 2.0.0'
gem 'clockwork'
gem 'devise'
gem 'github_webhook', '~> 1.1'
gem 'haml'
gem 'jquery-rails'
gem 'octokit'
gem 'omniauth-github'
gem 'sidekiq'
gem 'slack-ruby-client'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'database_cleaner'
  gem 'dotenv-rails'
  gem 'factory_girl'
  gem 'rspec-rails'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers'
  gem 'spring-commands-rspec'
  gem 'webmock'
end

group :development do
  gem 'spring'
  gem 'web-console', '>= 3.3.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
