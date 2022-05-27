class AnnouncePullRequestRule < ApplicationRule
  alias_record_as :pull_request

  trigger 'PullRequest', :created do
    !(pull_request.release? || crowdin_update?)
  end

  delegate :repo, to: :pull_request
  delegate :slack_channel, to: 'repo.board'

  def call
    SlackNotifier.notify(
      "Pull request opened by @#{pull_request.creator_username}",
      channel: slack_channel,
      attachments: {
        title: "#{repo.name}: #{pull_request.title}",
        title_link: pull_request.html_url,
        text: "`#{pull_request.head_branch}` => `#{pull_request.base_branch}`",
        color: 'good'
      }
    )
  end

  private

  def crowdin_update?
    pull_request.head_branch.match?(/^i18n_/)
  end
end
