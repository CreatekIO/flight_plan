class UnsuccessfulBuildOnMajorBranchRule < ApplicationRule
  alias_record_as :commit_status

  setting :branches, default: %w[develop main master]
  setting :slack_channel, default: proc { commit_status.repo.board.slack_channel }

  trigger 'CommitStatus', :created do
    commit_status.unsuccessful? && on_major_branch?
  end

  def call
    SlackNotifier.notify(
      ":warning: *Build failed on #{branch_names}*",
      channel: slack_channel,
      attachments: {
        title: "[#{commit_status.context}] #{commit_status.description.presence || 'Build failed'}",
        title_link: commit_status.url,
        color: 'danger'
      }
    )
  end

  private

  def on_major_branch?
    associated_major_branches.any?
  end

  def associated_major_branches
    @associated_major_branches ||= commit_status.branches.where(name: branches).load
  end

  def branch_names
    associated_major_branches.map { |branch| "`#{branch.name}`" }.sort.to_sentence
  end
end
