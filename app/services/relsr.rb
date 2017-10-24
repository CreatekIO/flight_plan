require 'octokit'
require 'colorize'

class Relsr

  attr_reader :repo_name, :issues, :release_branch_name, :extra_branches

  def initialize(repo_name:, issues:, extra_branches: [])
    @repo_name = repo_name
    @issues = issues
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
    puts 'done'.green
  end

  private

  def initialize_release_branch
    log "Creating release branch '#{release_branch_name}' on '#{repo_name}'..."  
    client.create_ref(repo_name, "heads/#{release_branch_name}", master.object.sha)
    puts 'done'.green
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
      puts 'done'.green
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

    issues.each do |issue|
      branch_names.each do |branch|
        if branch.include? "##{issue.number}"
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
    messages = issues.collect do |issue|
      "Connects ##{issue.number} - #{issue.title}"
    end 
    messages += extra_branches.collect do |branch|
      "Merging in additional branch '#{branch}'"
    end

    messages.join("\n")
  end

  def log(message)
  end
end
