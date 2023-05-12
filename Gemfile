source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.7'

gem 'rails', '~> 5.2.7'

gem 'blueprinter'
gem 'bootsnap', '~> 1.12.0', require: false
gem 'bugsnag'
gem 'business_time'
gem 'cancancan'
gem 'clockwork'
gem 'descriptive_statistics', require: 'descriptive_statistics/safe'
gem 'devise'
gem 'faraday'
gem 'faraday-retry'
gem 'flipper-redis'
gem 'flipper-ui'
gem 'github_webhook'
gem 'haml'
gem 'jbuilder'
gem 'jwt'
gem 'octokit'
gem 'omniauth-github'
gem 'omniauth-rails_csrf_protection'
gem 'pg', '~> 1.2.3'
gem 'puma'
gem 'ranked-model'
gem 'redis-namespace'
# v7 needs Redis v7, which is not yet supported by Redis Cloud:
# https://github.com/sidekiq/sidekiq/blob/main/docs/7.0-Upgrade.md#known-issues
gem 'sidekiq', '~> 6'
gem 'slack-ruby-client'
gem 'vite_rails'
gem 'wisper'

group :development, :test do
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'dotenv-rails'
  gem 'factory_bot'
  gem 'rspec-rails', '~> 5' # supports Rails 5.2 + 6.0
end

group :development do
  # loaded when running tests, but not in :test group as we don't want it on CI
  gem 'spring', '~> 3'
  gem 'spring-commands-rspec'
end

group :test do
  gem 'action-cable-testing'
  gem 'capybara'
  gem 'clockwork-test', require: 'clockwork/test'
  gem 'cuprite'
  gem 'rspec-retry'
  gem 'rspec-sidekiq'
  gem 'rspec_junit_formatter', require: false
  gem 'shoulda-matchers'
  gem 'webmock'
end
