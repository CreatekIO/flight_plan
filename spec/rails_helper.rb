ENV['RACK_ENV'] ||= 'test'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'spec_helper'
require "action_cable/testing"
require "rspec/rails/feature_check"

RSpec::Rails::FeatureCheck.module_eval do
  module_function

  def has_action_cable_testing?
    true
  end
end

require 'rspec/rails'

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

  config.include Clockwork::Test::RSpec::Matchers
  config.include ActiveSupport::Testing::TimeHelpers
end

RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec::Sidekiq.configure do |config|
  config.clear_all_enqueued_jobs = true
  config.warn_when_jobs_not_processed_by_sidekiq = false
end
