module OctokitClient
  extend ActiveSupport::Concern

  LEGACY_GLOBAL_TOKEN = ENV['GITHUB_API_TOKEN'].freeze

  def self.legacy_client
    Octokit::Client.new(access_token: LEGACY_GLOBAL_TOKEN)
  end

  class Token
    SESSION_KEY = 'github.token'.freeze

    # See https://github.blog/2021-04-05-behind-githubs-new-authentication-token-formats/
    #
    # > `ghp` for GitHub personal access tokens
    # > `gho` for OAuth access tokens
    # > `ghu` for GitHub [app] user-to-server tokens
    # > `ghs` for GitHub [app] server-to-server tokens
    # > `ghr` for [app] refresh tokens
    def self.write_into_session(session, token)
      existing = session[SESSION_KEY]

      case existing
      when Hash
        type = case token.to_s
        when /^gho_/ # OAuth app ("legacy")
          'oauth'
        when /^ghu_/ # GitHub app ("user-to-server")
          'app'
        else
          raise ArgumentError, "can't handle token with prefix '#{token.to_s.split("_").first}'"
        end

        existing[type] = token
      when String
        session[SESSION_KEY] = { 'oauth' => existing }
        write_into_session(session, token)
      else # nil
        session[SESSION_KEY] = {}
        write_into_session(session, token)
      end
    end

    def self.read_from_session(session)
      token = session[SESSION_KEY]

      case token
      when Hash
        new(**token.symbolize_keys)
      when String # "legacy" storage
        new(oauth: token)
      else # nil, most likely
        raise ArgumentError, 'no token stored in session'
      end
    end

    attr_reader :oauth, :app

    def initialize(oauth: nil, app: nil)
      @oauth = oauth
      @app = app
    end

    def to_s
      (oauth.presence || app).to_s
    end

    def for(repo)
      repo.uses_app? ? app : oauth
    end
  end

  module ClassMethods
    def octokit_methods(*names, prefix_with: nil, add_aliases: false)
      prefix_args = Array.wrap(prefix_with).map(&:to_s).join(', ')
      @octokit_module ||= const_set(:OctokitClientMethods, Module.new).tap do |mod|
        include mod
      end

      names.each do |name|
        @octokit_module.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def octokit_#{name}(*args)
            octokit.#{name}(
              #{prefix_args + ',' if prefix_args.present?}
              *args
            )
          end
        RUBY

        next unless add_aliases

        @octokit_module.send(:alias_method, name, "octokit_#{name}")
      end
    end
  end

  def octokit
    @octokit ||= begin
      options = octokit_client_options
      access_token = options.delete(:access_token)
      options[:access_token] = access_token.to_s if access_token

      Octokit::Client.new(options)
    end
  end

  def octokit_client_options
    {}
  end

  def octokit_token=(new_token)
    octokit.access_token = (new_token.presence && new_token.to_s)
  end

  def without_octokit_pagination
    original = octokit.auto_paginate
    octokit.auto_paginate = false

    yield
  ensure
    octokit.auto_paginate = original
  end

  def retry_as_app_if_fails(repo)
    retried = false
    original_client = @octokit

    begin
      yield
    rescue Octokit::NotFound => error
      raise if octokit.bearer_authenticated? \
        || octokit.access_token == LEGACY_GLOBAL_TOKEN \
        || retried

      logger.warn "Got #{error.class}: #{error.message}...retrying with global API token"

      @octokit = repo.octokit
      retried = true
      retry
    ensure
      @octokit = original_client
    end
  end
end
