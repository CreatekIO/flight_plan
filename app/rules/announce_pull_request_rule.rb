class AnnouncePullRequestRule < ApplicationRule
  alias_record_as :pull_request

  setting :slack_channel, default: proc { repo.board.slack_channel }

  trigger 'PullRequest', :created do
    pull_request.open? && !(pull_request.release? || crowdin_update?)
  end

  delegate :repo, to: :pull_request

  TEMPLATE = "Pull request *%{slug}#%{number}* opened by *@%{username}*".freeze

  def call
    SlackNotifier.notify(
      format(
        TEMPLATE,
        slug: repo.slug,
        number: pull_request.number,
        username: pull_request.creator_username
      ),
      channel: slack_channel,
      attachments: {
        title: pull_request.title,
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
