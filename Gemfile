source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.6'

gem 'rails', '~> 5.2.4', '>= 5.2.4.5'

gem 'activerecord-import'
gem 'blueprinter'
gem 'bootsnap', '>= 1.1.0', require: false
gem 'bugsnag'
gem 'business_time'
gem 'cancancan'
gem 'clockwork'
gem 'createk_data_migrator'
gem 'descriptive_statistics', require: 'descriptive_statistics/safe'
gem 'devise'
gem 'flipper-redis'
gem 'flipper-ui'
gem 'github_webhook'
gem 'haml'
gem 'jbuilder'
gem 'jwt'
gem 'octokit'

# upgrade once Devise updated
gem 'omniauth-github', '~> 1'
gem 'omniauth-rails_csrf_protection', '< 1'

gem 'pg'
gem 'puma'
gem 'ranked-model'
gem 'redis-namespace'
gem 'sidekiq'
gem 'slack-ruby-client'
gem 'webpacker', '6.0.0.beta.6'
gem 'wisper'

group :development, :test do
  gem 'active_record_query_trace'
  gem 'bullet'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'dotenv-rails'
  gem 'factory_bot'
  gem 'rspec-rails', '~> 5'
  gem 'spring-commands-rspec'
end

group :development do
  gem 'spring'
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
  gem 'timecop'
  gem 'webmock'
end
