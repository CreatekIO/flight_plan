source 'https://rubygems.org'

ruby '2.6.6'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.2'

gem 'activerecord-import'
gem 'bugsnag'
gem 'business_time'
gem 'cancancan'
gem 'clockwork'
gem 'createk_data_migrator'
gem 'descriptive_statistics', require: 'descriptive_statistics/safe'
gem 'devise'
gem 'flipper-redis'
gem 'github_webhook'
gem 'haml'
gem 'jbuilder'
gem 'jquery-rails'
gem 'octokit'

# upgrade once Devise updated
gem 'omniauth-github', '~> 1'
gem 'omniauth-rails_csrf_protection', '< 1'

gem 'pg'
gem 'puma'
gem 'ranked-model'
gem 'redis-namespace'
gem 'sass-rails'
gem 'sidekiq'
gem 'slack-ruby-client'
gem 'sprockets'
gem 'uglifier'
gem 'webpacker', '~> 3.4.3'

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
  gem 'cuprite'
  gem 'rspec-retry'
  gem 'rspec-sidekiq'
  gem 'rspec_junit_formatter', require: false
  gem 'shoulda-matchers'
  gem 'timecop'
  gem 'webmock'
end
