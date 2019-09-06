module OctokitClient
  extend ActiveSupport::Concern

  module ClassMethods
    def octokit_methods(*names, prefix_with: nil)
      prefix_args = Array.wrap(prefix_with).map(&:to_s).join(', ')
      @octokit_module ||= const_set(:OctokitClientMethods, Module.new).tap do |mod|
        include mod
      end

      names.each do |name|
        @octokit_module.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{name}(*args)
            octokit.#{name}(
              #{prefix_args + ',' if prefix_args.present?}
              *args
            )
          end
        RUBY
      end
    end
  end

  def octokit
    @octokit ||= Octokit::Client.new
  end

  def octokit_token=(new_token)
    octokit.access_token = new_token
  end

  def retry_with_global_token_if_fails
    retried = false

    begin
      yield
    rescue Octokit::NotFound => error
      raise if octokit.access_token == Octokit.access_token || retried

      logger.warn "Got #{error.class}: #{error.message}...retrying with global API token"

      self.octokit_token = Octokit.access_token
      retried = true
      retry
    end
  end
end
