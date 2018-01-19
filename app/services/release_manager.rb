class ReleaseManager
  def initialize(board, repo)
    @board = board
    @repo = repo
    @release_branch_name = Time.now.strftime('release/%Y%m%d-%H%M%S')
    @merge_conflicts = []
  end

  def open_pr?
    repo.pull_requests.any? do |pr|
      pr[:base][:ref] == 'master'
    end
  end

  def create_release
    return unless unmerged_tickets.any?
    create_release_branch
    if create_pull_request
      create_release_model
      announce_pr_opened if send_to_slack?
    end
  end

  def merge_prs(branch = 'master')
    repo.pull_requests.each do |pr|
      next unless pr[:base][:ref] == branch
      next if pr[:title].include?('CONFLICTS')
      log "Merging PR ##{pr[:number]} - #{pr[:title]}"

      repo.merge_pull_request(pr[:number])
    end
  end

  private

  attr_reader :board, :repo, :release_branch_name, :merge_conflicts, :remote_pr

  def create_release_model
    release = Release.new(
      repo: repo,
      board: board,
      title: release_pr_name,
      source_branch: release_branch_name,
      target_branch: 'master',
      remote_title: remote_pr[:title],
      remote_id: remote_pr[:id],
      remote_number: remote_pr[:number],
      remote_url: remote_pr[:html_url],
      remote_state: remote_pr[:state]
    )
    unmerged_tickets.each do |ticket|
      release.board_tickets << board.board_tickets.find_by(ticket: ticket)
    end
    release.save
  end

  def release_pr_name
    if merge_conflicts.any?
      "#{release_branch_name} (CONFLICTS)"
    else
      release_branch_name
    end
  end

  def extra_branches
    @extra_branches ||=
      if board.additional_branches_regex.present?
        begin
          repo.regex_branches(Regexp.new(board.additional_branches_regex))
        rescue RegexpError
          []
        end
      else
        []
      end
  end

  def unmerged_tickets
    @unmerged_tickets ||= tickets.reject { |t| t.merged_to?('master') }
  end

  def create_release_branch
    initialize_release_branch
    merge_work_branches
    repo.update_merged_tickets
  end

  def create_pull_request
    log 'Creating pull request...'
    @remote_pr = repo.create_pull_request(
      'master',
      release_branch_name,
      release_pr_name,
      pr_body
    )
    log 'done'
    true
  rescue Octokit::UnprocessableEntity
    log 'Could not create pull request, deleting branch'
    repo.delete_branch(release_branch_name)
    false
  end

  def initialize_release_branch
    log "Creating release branch '#{release_branch_name}' on '#{repo.remote_url}'..."
    repo.create_ref("heads/#{release_branch_name}", master.object.sha)
    log 'done'
  end

  def merge_work_branches
    branches_to_merge.each do |work_branch|
      begin
        log "Merging '#{work_branch}' into release..."
        repo.merge(
          release_branch_name,
          work_branch,
          commit_message: "Merging #{work_branch} into release"
        )
        log 'done'
      rescue Octokit::Conflict
        merge_conflicts << work_branch
      end
    end
  end

  def tickets
    board.deploy_swimlane.tickets.where(repo_id: repo.id)
  end

  def branches_to_merge
    unmerged_tickets.flat_map(&:branch_names) + extra_branches
  end

  def master
    @master ||= repo.refs('heads/master')
  end

  def pr_body
    messages = ['**Issues**'] + unmerged_tickets.collect do |ticket|
      "Connects ##{ticket.remote_number} - #{ticket.remote_title}"
    end

    messages += extra_branches_pr_messages if extra_branches.any?
    messages += merge_conflict_pr_messages if merge_conflicts.any?

    messages.join("\n")
  end

  def extra_branches_pr_messages
    ['', '**Extra branches**'] + extra_branches.collect do |branch|
      "Merging in additional branch '#{branch}'"
    end
  end

  def merge_conflict_pr_messages
    messages = [
      '',
      '**Conflicts**',
      'Could not merge all branches. Please manually merge and resolve conflicts:',
      '```',
      '    git fetch',
      "    git checkout #{release_branch_name}"
    ]
    merge_conflicts.each do |work_branch|
      messages << "    git merge origin/#{work_branch}"
      messages << '    // resolve conflicts and finish merge'
    end
    messages + [
      '    git push',
      '```'
    ]
  end

  def send_to_slack?
    ENV['SLACK_API_TOKEN'].present?
  end

  def announce_pr_opened
    tickets = unmerged_tickets.collect do |ticket|
      "• #{ticket.remote_number} : #{ticket.remote_title}"
    end

    attachments = [
      {
        fallback: "#{repo.name} : #{release_pr_name}",
        title: "#{repo.name} : #{release_pr_name}",
        title_link: remote_pr[:html_url],
        text: tickets.join("\n"),
        color: 'good'
      }
    ]

    if merge_conflicts.any?
      attachments << {
        title: 'This PR has conflicts and can not be merged automatically.',
        color: 'warning'
      }
    end

    slack_client.chat_postMessage(
      channel: ENV['SLACK_CHANNEL'],
      text: '*Pull Request Created*',
      attachments: attachments,
      as_user: true
    )
  end

  def slack_client
    Slack::Web::Client.new
  end

  def log(message)
    puts message
  end
end
