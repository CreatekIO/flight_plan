class UnsuccessfulBuildOnMajorBranchRule < ApplicationRule
  alias_record_as :commit_status

  setting :branches, default: %w[develop main master]
  setting :slack_channel, default: proc { commit_status.repo.board.slack_channel }
  setting :ignored_contexts, default: nil

  delegate :context, :description, to: :commit_status

  trigger 'CommitStatus', :created do
    commit_status.unsuccessful? && on_major_branch? && for_failing_build? && !ignored?
  end

  def call
    SlackNotifier.notify(
      ":warning: *Build failed on #{branch_names} - #{context}*",
      channel: slack_channel,
      attachments: {
        title: description.presence || 'Build failed',
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

  def for_failing_build?
    return true unless context =~ /^buildkite/
    return true if description.blank? # unable to tell, assume the worst

    description !~ /\b(is failing|skipped|cancell?ed)\b/
  end

  def ignored?
    TextMatcher.from(ignored_contexts).matches?(context)
  end
end
