class ReleaseManager
  include OctokitClient

  class AllBranchesConflict < StandardError; end

  BRANCH_PREFIX = 'release/'.freeze

  octokit_methods(
    :pull_requests, :merge_pull_request, :create_pull_request,
    :create_ref, :merge, :refs, :delete_branch,
    prefix_with: 'repo.slug'
  )

  def initialize(board, repo)
    @board = board
    @repo = repo
    @release_branch_name = Time.now.strftime("#{BRANCH_PREFIX}%Y%m%d-%H%M%S")
    @merge_conflicts = []
    @octokit = repo.octokit
  end

  def open_pr?
    octokit_pull_requests.any? { |pr| release_pr?(pr) }
  end

  def create_release
    return unless unmerged_tickets.any?
    create_release_branch

    announce_pr_opened if create_pull_request
  end

  def merge_prs(branch = repo.deployment_branch)
    octokit_pull_requests.each do |pr|
      next unless release_pr?(pr, base: branch)
      next if pr[:title].include?('CONFLICTS')
      log "Merging PR ##{pr[:number]} - #{pr[:title]}"

      octokit_merge_pull_request(pr[:number])
      announce_pr_merged(pr)
    end
  end

  def unmerged_tickets
    @unmerged_tickets ||= tickets.reject do |ticket|
      ticket.merged_to?(repo.deployment_branch)
    end
  end

  private

  attr_reader :board, :repo, :release_branch_name, :merge_conflicts, :remote_pr

  def release_pr?(remote_pr, base: repo.deployment_branch)
    remote_pr[:base][:ref] == base && Branch.release?(remote_pr[:head][:ref])
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

  def create_release_branch
    initialize_release_branch
    merge_work_branches
    repo.update_merged_tickets
  end

  def create_pull_request
    raise AllBranchesConflict, 'All branches in release had merge conflicts' if all_branches_conflict?

    log 'Creating pull request...'
    @remote_pr = octokit_create_pull_request(
      repo.deployment_branch,
      release_branch_name,
      release_pr_name,
      pr_body
    )
    log 'done'
    true
  rescue Octokit::Error, AllBranchesConflict => error
    log 'Could not create pull request, deleting branch'
    announce_pr_failed(error)
    octokit_delete_branch(release_branch_name)
    false
  end

  def initialize_release_branch
    log "Creating release branch '#{release_branch_name}' on '#{repo.slug}'..."
    octokit_create_ref("heads/#{release_branch_name}", deployment_branch_head_sha)
    log 'done'
  end

  def merge_work_branches
    branches_to_merge.each do |work_branch|
      begin
        log "Merging '#{work_branch}' into release..."
        octokit_merge(
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
    @branches_to_merge ||= unmerged_tickets.flat_map(&:branch_names) + extra_branches
  end

  def deployment_branch_head_sha
    @deployment_branch_head_sha ||= octokit_refs("heads/#{repo.deployment_branch}").object.sha
  end

  def all_branches_conflict?
    branches_to_merge.size == merge_conflicts.size
  end

  def pr_body
    messages = ['**Issues**'] + unmerged_tickets.collect do |ticket|
      "Connects ##{ticket.number} - #{ticket.title}"
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

  def announce_pr_opened
    tickets = unmerged_tickets.collect do |ticket|
      "• #{ticket.number} : #{ticket.title}"
    end

    attachments = [
      {
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

    SlackNotifier.notify(
      '*Pull Request Created*',
      channel: board.slack_channel,
      attachments: attachments
    )
  end

  def announce_pr_merged(pr)
    SlackNotifier.notify(
      '*Pull Request Merged*',
      channel: board.slack_channel,
      attachments: {
        title: "#{repo.name}: Merged PR ##{pr[:number]} #{pr[:title]}",
        title_link: pr[:html_url],
        text: pr[:body],
        color: 'good'
      }
    )
  end

  def announce_pr_failed(error)
    SlackNotifier.notify(
      '*Pull Request Failed*',
      channel: board.slack_channel,
      attachments: {
        title: "#{repo.name}: Failed to create release",
        text: error.message,
        color: 'danger'
      }
    )
  end

  def log(message)
    Rails.logger.info message
  end
end
