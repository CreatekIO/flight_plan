class Relsr

  #TODO: write tests
  #TODO: recover from merge conflicts
  #TODO: extra_branches
  #TODO: logging

  attr_reader :repo_name, :tickets, :release_branch_name, :extra_branches

  def initialize(repo_name:, tickets:, extra_branches: [])
    @repo_name = repo_name
    @tickets = tickets
    @release_branch_name = Time.now.strftime('release/%Y%m%d-%H%M%S')
    @extra_branches = extra_branches
    Octokit.auto_paginate = true
  end

  def create_release_branch
    initialize_release_branch
    merge_work_branches
  end

  def create_pull_request
    log "Creating Pull Request..."
    client.create_pull_request(
      repo_name,
      'master',
      release_branch_name,
      release_branch_name,
      pr_body
    )
    log 'done'
    true
  rescue Octokit::UnprocessableEntity
    log 'Could not create pull request, deleting branch'
    client.delete_branch(repo_name, release_branch_name)
    false 
  end

  private

  def initialize_release_branch
    log "Creating release branch '#{release_branch_name}' on '#{repo_name}'..."  
    client.create_ref(repo_name, "heads/#{release_branch_name}", master.object.sha)
    log 'done'
  end

  def merge_work_branches
    branches_to_merge.each do |work_branch|
      log "Merging '#{work_branch}' into release..."
      client.merge(
        repo_name, 
        release_branch_name, 
        work_branch, 
        commit_message: "Merging #{work_branch} into release"
      )
      log 'done'
    end
  end

  def client
    @client ||= Octokit::Client.new(netrc: true)
  end

  def repo
    @repo ||= client.repo(repo_name)
  end

  def branch_names
    @branch_names ||= client.branches(repo_name).collect { |b| b.name }
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
    @master ||= client.refs(repo_name, 'heads/master')
  end

  def pr_body
    messages = tickets.collect do |ticket|
      "Connects ##{ticket.remote_number} - #{ticket.remote_title}"
    end 
    messages += extra_branches.collect do |branch|
      "Merging in additional branch '#{branch}'"
    end

    messages.join("\n")
  end

  def log(message)
    puts message
  end
end
