ENV['RACK_ENV'] ||= 'test'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'spec_helper'
require 'rspec/rails'
require 'action_cable/testing/rspec'

Dir[Rails.root.join('spec/support/*.rb')].each { |file| require file }
Dir[Rails.root.join('spec/support/shared_contexts/*.rb')].each { |file| require file }
Dir[Rails.root.join('spec/support/shared_examples/*.rb')].each { |file| require file }

ActiveRecord::Migration.maintain_test_schema!

# silence warnings from Faraday on CircleCI
ENV.delete('no_proxy')
ENV.delete('NO_PROXY')

RSpec.configure do |config|
  config.use_transactional_fixtures = true

  config.infer_spec_type_from_file_location!

  config.filter_rails_from_backtrace!
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system
end

RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec::Sidekiq.configure do |config|
  config.clear_all_enqueued_jobs = true
  config.warn_when_jobs_not_processed_by_sidekiq = false
end
