class PullRequestRefreshWorker
  include Sidekiq::Worker
  sidekiq_options retry: 5

  def perform(pull_request_id)
    pull_request = PullRequest.find(pull_request_id)
  rescue ActiveRecord::RecordNotFound => error
    Bugnsag.notify(error)
  else
    PullRequestRefresher.new(pull_request).run
  end
end
