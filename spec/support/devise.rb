module DeviseHelpers
  def self.included(base)
    base.include Devise::Test::IntegrationHelpers
    base.include Overrides
    super
  end

  module Overrides
    def sign_in(user, scope: nil, github_token: nil)
      super(user, scope: scope).tap do |result|
        return result if github_token.blank?

        token = case github_token
        when true, :app
          { 'app' => 'ghu_token' }
        when :oauth
          { 'oauth' => 'gho_token' }
        when :both
          { 'oauth' => 'gho_token', 'app' => 'ghu_token' }
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
