class ReleaseManager

  DEPLOY_DELAY = 10.minutes

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
    if unmerged_tickets.any?
      create_release_branch
      create_pull_request
    end
  end

  def merge_prs(branch = 'master')
    repo.pull_requests.each do |pr|
      next unless pr[:base][:ref] == branch
      next if pr[:title].include?('CONFLICT')
      log "Merging PR ##{pr[:number]} - #{pr[:title]}"

      repo.merge_pull_request(pr[:number])
    end
  end

  private

  attr_reader :board, :repo, :release_branch_name, :merge_conflicts

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
    repo.create_pull_request(
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

  def log(message)
    puts message
  end
end
