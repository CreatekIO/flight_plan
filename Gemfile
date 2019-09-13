source 'https://rubygems.org'

ruby '2.4.1'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.1.4'

gem 'mysql2', '>= 0.3.18', '< 0.5'
gem 'puma', '~> 3.7'
gem 'sass-rails', '~> 5.0'
gem 'sprockets',  '~> 3.7.2'
gem 'uglifier', '>= 1.3.0'
gem 'webpacker'

gem 'coffee-rails', '~> 4.2'
gem 'jbuilder', '~> 2.5'
gem 'turbolinks', '~> 5'

gem 'bootstrap-sass', '~> 3.4.1'
gem 'bugsnag'
gem 'business_time'
gem 'cancancan', '~> 2.0.0'
gem 'clockwork'
gem 'createk_data_migrator'
gem 'devise', '~> 4.6.0'
gem 'github_webhook', '~> 1.1'
gem 'haml'
gem 'jquery-rails'
gem 'octicons_helper'
gem 'octokit'
gem 'omniauth-github'
gem 'omniauth-rails_csrf_protection', '~> 0.1'
gem 'ranked-model', '~> 0.4'
gem 'sidekiq'
gem 'slack-ruby-client'

# Fix versions of transitive dependencies due to vulnerabilities
gem 'ffi', '~> 1.10.0'
gem 'loofah', '~> 2.2.3'
gem 'nokogiri', '~> 1.10.1'
gem 'rack', '~> 2.0.6'
gem 'rubyzip', '~> 1.2.2'

group :development, :test do
  gem 'active_record_query_trace'
  gem 'bullet'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'capybara', '~> 2.15.1'
  gem 'capybara-screenshot'
  gem 'database_cleaner'
  gem 'dotenv-rails'
  gem 'factory_bot'
  gem 'rspec-rails', '3.7.0'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers'
  gem 'spring-commands-rspec'
  gem 'timecop'
  gem 'webmock'
end

group :development do
  gem 'spring'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'action-cable-testing'
  gem 'rspec-sidekiq'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
