module InstallationImporter
  ORGS = ENV['PERMITTED_INSTALLATION_ORGS'].to_s.downcase.split(',').freeze

  class << self
    def import(payload)
      action, installation, repos = payload.values_at(:action, :installation, :repositories)

      if action == 'created' && !user_or_org_permitted?(installation[:account][:login])
        App.uninstall(installation_id: installation[:id])
        return
      end

      case action
      when 'created', 'added', 'unsuspend'
        (payload[:repositories_added] || repos).each do |repo|
          capture_errors { Installation.new(repo, installation[:id]).import }
        end
      when 'deleted', 'removed', 'suspend'
        (payload[:repositories_removed] || repos).each do |repo|
          capture_errors { remove_installation_from(repo[:id]) }
        end
      when 'new_permissions_accepted'
        # do nothing
      else
        Rails.logger.warn("Unknown installation action: #{action}")
      end
    end

    private

    def capture_errors
      yield
    rescue => error
      Bugsnag.notify(error)
    end

    def user_or_org_permitted?(name)
      ORGS.include?(name.downcase)
    end

    def remove_installation_from(remote_repo_id)
      repo = Repo.find_by(remote_id: remote_repo_id)
      return if repo.blank?

      repo.update!(remote_installation_id: nil)
    end
  end

  class Installation
    DEFAULT_DEPLOYMENT_BRANCH = 'master'.freeze

    delegate :octokit, to: :repo

    def initialize(payload, installation_id)
      @payload = payload
      @slug = payload[:full_name]
      @installation_id = installation_id
      @repo_created = false
    end

    def import
      import_repo
      remove_old_webhook
    end

    private

    attr_reader :payload, :slug, :installation_id

    def repo_created?
      @repo_created
    end

    def repo
      @repo ||= Repo.find_or_initialize_by(remote_id: payload[:id]) do |new_repo|
        @repo_created = true

        new_repo.name = payload[:name]
        new_repo.slug = slug # TODO: handle renames by creating aliases?
        new_repo.deployment_branch = DEFAULT_DEPLOYMENT_BRANCH
      end
    end

    def import_repo
      repo.update!(remote_installation_id: installation_id)
    end

    def remove_old_webhook
      return if repo_created?

      # Note that app webhooks aren't returned from this endpoint
      octokit.hooks(slug).each do |webhook|
        next unless webhook[:config][:url].starts_with?('https://flightplan.createk.io/')

        octokit.remove_hook(slug, webhook[:id])
      end
    end
  end
end
