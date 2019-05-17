class AddAdditionalInfoToTickets < ActiveRecord::Migration["4.2"]
  def up
    p ApplicationRecord.connection_config

    Repo.all.each do |repo|
      repo_full_name = repo.remote_url

      say_with_time "Updating repo #{repo_full_name}" do
        say_with_time 'Importing labels' do
          octokit.labels(repo_full_name).each do |remote_label|
            say_with_time "Importing label '#{remote_label.name}'" do
              Label.import(remote_label.to_hash, repo)
            end
          end
        end

        say_with_time 'Importing milestones' do
          octokit.milestones(repo_full_name).each do |remote_milestone|
            say_with_time "Importing milestone '#{remote_milestone.title}'" do
              Milestone.import(remote_milestone.to_hash, repo)
            end
          end
        end

        remote_repo = { full_name: repo_full_name }

        import_issues(remote_repo, state: 'open')
        import_issues(remote_repo, state: 'closed', sort: 'updated', direction: 'desc', per_page: 50)

        octokit.issues_comments(repo_full_name, sort: 'updated', direction: 'desc').each do |remote_comment|
          say_with_time "Updating comment #{remote_comment[:html_url]}" do
            Comment.import({ comment: remote_comment.to_hash }, repo)
          end
        end
      end
    end
  end

  private

  def import_issues(remote_repo, options)
    octokit.issues(remote_repo[:full_name], options).each do |remote_issue|
      next if remote_issue.pull_request.present? # actually a pull request

      say_with_time "Updating #{remote_issue.state} issue ##{remote_issue.number}" do
        Ticket.import(remote_issue.to_hash, remote_repo)
      end
    end
  end

  def octokit
    @octokit ||= Octokit::Client.new.tap do |c|
      c.auto_paginate = false
      c.per_page = 100
    end
  end
end
