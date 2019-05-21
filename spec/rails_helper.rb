ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
abort('The Rails environemtn is running in a production mode!') if Rails.env.production?

require 'spec_helper'
require 'rspec/rails'
require 'webmock/rspec'
require 'capybara-screenshot/rspec'
require 'sidekiq/testing'

Dir[Rails.root.join('spec/support/*.rb')].each { |file| require file }
Dir[Rails.root.join('spec/support/helpers/*.rb')].each { |file| require file }
Dir[Rails.root.join('spec/support/shared_contexts/*.rb')].each { |file| require file }
Dir[Rails.root.join('spec/support/shared_examples/*.rb')].each { |file| require file }

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.use_transactional_fixtures = false

  config.infer_spec_type_from_file_location!

  config.filter_rails_from_backtrace!
  config.include Warden::Test::Helpers
end

RSpec::Matchers.define_negated_matcher :not_change, :change
