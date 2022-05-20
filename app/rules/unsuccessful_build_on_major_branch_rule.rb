class UnsuccessfulBuildOnMajorBranchRule < ApplicationRule
  BRANCHES = %w[develop main master].freeze

  alias_record_as :commit_status

  trigger 'CommitStatus', :created do
    commit_status.unsuccessful? && on_major_branch?
  end

  def call
    slack.notify(
      ":warning: *Build failed on #{branch_names}*",
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
    @associated_major_branches ||= commit_status.branches.where(name: BRANCHES).load
  end

  def branch_names
    associated_major_branches.map { |branch| "`#{branch.name}`" }.sort.to_sentence
  end

  def slack
    @slack ||= SlackNotifier.new(commit_status.repo.board.slack_channel)
  end
end
