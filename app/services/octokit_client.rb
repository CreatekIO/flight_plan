module OctokitClient
  extend ActiveSupport::Concern

  LEGACY_GLOBAL_TOKEN = ENV['GITHUB_API_TOKEN'].freeze

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
    @octokit ||= Octokit::Client.new(octokit_client_options)
  end

  def octokit_client_options
    {}
  end

  def octokit_token=(new_token)
    octokit.access_token = new_token
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
