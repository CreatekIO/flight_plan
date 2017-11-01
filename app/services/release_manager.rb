class ReleaseManager

  #TODO: write tests
  #TODO: extra_branches
  #TODO: logging
  #TODO: dont create new PR after this has merged (branch diff)

  DEPLOY_DELAY = 10.minutes

  def initialize(board, repo)
    @board = board
    @repo = repo
    @release_branch_name = Time.now.strftime('release/%Y%m%d-%H%M%S')
    @extra_branches = []
    @merge_conflicts = []
  end

  def open_pr?
    client.pull_requests(repo.remote_url).any? do |pr|
      pr.base.ref == 'master'
    end
  end

  def cooled_off?
    Time.now >= deploy_after
  end

  def create_release
    if tickets.any?
      create_release_branch
      create_pull_request
    end
  end

  private

  attr_reader :board, :repo, :release_branch_name, :extra_branches, :merge_conflicts

  def create_release_branch
    initialize_release_branch
    merge_work_branches
  end

  def create_pull_request
    log "Creating pull request..."
    client.create_pull_request(
      repo.remote_url,
      'master',
      release_branch_name,
      release_branch_name,
      pr_body
    )
    log 'done'
    true
  rescue Octokit::UnprocessableEntity
    log 'Could not create pull request, deleting branch'
    client.delete_branch(repo.remote_url, release_branch_name)
    false 
  end

  def initialize_release_branch
    log "Creating release branch '#{release_branch_name}' on '#{repo.remote_url}'..."  
    client.create_ref(repo.remote_url, "heads/#{release_branch_name}", master.object.sha)
    log 'done'
  end

  def merge_work_branches
    branches_to_merge.each do |work_branch|
      begin
        log "Merging '#{work_branch}' into release..."
        client.merge(
          repo.remote_url, 
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

  def client
    @client ||= Octokit::Client.new(netrc: true)
  end

  def repo
    @repo ||= client.repo(repo.remote_url)
  end

  def tickets
    board.deploy_swimlane.tickets.where(repo_id: repo.id)
  end

  def branch_names
    @branch_names ||= client.branches(repo.remote_url).collect { |b| b.name }
  end

  def branches_to_merge
    branches_to_merge = []

    tickets.each do |ticket|
      branch_names.each do |branch|
        if branch.include? "##{ticket.remote_number}"
          branches_to_merge << branch
        end
      end
    end
    branches_to_merge + extra_branches
  end

  def master
    @master ||= client.refs(repo.remote_url, 'heads/master')
  end

  def pr_body
    messages = tickets.collect do |ticket|
      "Connects ##{ticket.remote_number} - #{ticket.remote_title}"
    end 

    messages += extra_branches.collect do |branch|
      "Merging in additional branch '#{branch}'"
    end

    if merge_conflicts.any?
      messages << 'Could not merge all branches. Please manually merge and resolve conflicts for the following:'
      messages << '```'
      messages << '    git fetch'
      messages << "    git checkout #{release_branch_name}"
      merge_conflicts.each do |work_branch|
        messages << "    git merge origin/#{work_branch}"
        messages << "    // resolve conflicts and finish merge"
      end
      messages << "    git push"
    end

    messages.join("\n")
  end


  def log(message)
  end

  def deploy_after
    last_ticket = board.deploy_swimlane.board_tickets.order(:updated_at).last!

    deploy_after = last_ticket.updated_at + DEPLOY_DELAY

    if deploy_after < Time.parse('9am')
      deploy_after = deploy_after.change(hour: 9, minute: 0, second: 0)
    elsif deploy_after > Time.parse('5pm')
      deploy_after = deploy_after.change(hour: 9, minute: 0, second: 0)
      deploy_after += 1.day
    end

    loop do
      break if (1..5).include? deploy_after.wday
      deploy_after += 1.day
    end

    deploy_after
  rescue ActiveRecord::RecordNotFound
    nil
  end

end
