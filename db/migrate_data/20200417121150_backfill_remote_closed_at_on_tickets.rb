class BackfillRemoteClosedAtOnTickets < ActiveRecord::Migration["4.2"]
  disable_ddl_transaction!

  def up
    @error_count = 0
    say "#{existing_ticket_ids.size} existing tickets found"

    Repo.pluck(:id, :remote_url).each do |(repo_id, repo_full_name)|
      say_with_time "Updating #{repo_full_name}" do
        params = {
          state: 'closed',
          sort: 'updated',
          direction: 'desc',
        }

        earliest = Ticket.where(repo_id: repo_id).minimum(:remote_created_at)
        params[:since] = earliest if earliest.present?

        octokit.issues(repo_full_name, params).each do |remote_issue|
          unless existing_ticket_ids.include?(remote_issue.id)
            say "Skipping #{remote_issue.id.inspect} as not already in DB"
            next
          end

          if migrated_ticket_ids.include?(remote_issue.id)
            say "Skipping #{remote_issue.id} as already migrated"
            next
          end

          say_with_time "Importing #{repo_full_name}##{remote_issue.number}" do
            import_ticket(remote_issue, repo_full_name)
          end
        end
      end
    end

    say_with_time "Mopping up any leftover tickets" do
      scope = Ticket.where(remote_state: 'closed', remote_closed_at: nil)
      say "Found #{scope} tickets"

      scope.joins(:repo).pluck(
        Repo.arel_table[:remote_url],
        :remote_number
      ).each do |(repo_full_name, number)|
        remote_issue = octokit.issue(repo_full_name, number)

        import_ticket(remote_issue, repo_full_name)
      end
    end

    say "Done, with #{@error_count} errors"
  end

  private

  def octokit
    @octokit ||= Octokit::Client.new.tap do |c|
      c.per_page = 100

      c.middleware = c.middleware.dup.tap do |middleware|
        middleware.insert(
          middleware.handlers.size - 1, # before adapter
          Faraday::Response::Logger,
          logger,
          bodies: false,
          headers: false
        )
      end
    end
  end

  def existing_ticket_ids
    @existing_ticket_ids ||= begin
      Ticket.pluck(:remote_id).each_with_object(Set.new) do |id, set|
        set.add(id.to_i)
      end
    end
  end

  def migrated_ticket_ids
    @migrated_ticket_ids ||= begin
      Ticket.where.not(remote_closed_at: nil).pluck(:remote_id).each_with_object(Set.new) do |id, set|
        set.add(id.to_i)
      end
    end
  end

  def import_ticket(remote_issue, repo_full_name)
    # Some bodies are too long and trigger an error, FIXME another time
    Ticket.import(remote_issue.to_hash.except(:body), full_name: repo_full_name)
  rescue => error
    @error_count += 1

    say "Failed to import: #{error.class}: #{error.message}"
    Bugsnag.notify(error)

    raise if @error_count > 60
  end
end
