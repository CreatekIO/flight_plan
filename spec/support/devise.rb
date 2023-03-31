module DeviseHelpers
  def self.included(base)
    base.include Devise::Test::IntegrationHelpers
    base.include Overrides
    super
  end

  module Overrides
    def sign_in(user, scope: nil, github_token: true)
      super(user, scope: scope).tap do |result|
        return result if github_token.blank?

        token = case github_token
        when true, :app
          { 'app' => generate(:github_app_token) }
        when :oauth
          { 'oauth' => generate(:github_oauth_token) }
        when :both
          {
            'oauth' => generate(:github_oauth_token),
            'app' => generate(:github_app_token)
          }
        when Hash
          github_token.stringify_keys
        else # String
          github_token
        end

        Warden.on_next_request do |proxy|
          proxy.session['github.token'] = token
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include DeviseHelpers, type: :request
  config.include DeviseHelpers, type: :system
end
