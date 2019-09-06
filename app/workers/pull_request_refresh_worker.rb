class PullRequestRefreshWorker
  include Sidekiq::Worker
  sidekiq_options retry: 5

  def self.update_after_import(pull_request)
    return if pull_request.new_record?
    return if pull_request.merge_status_known?

    perform_in(1.minute, pull_request.id)
  end

  def perform(pull_request_id)
    pull_request = PullRequest.find(pull_request_id)
  rescue ActiveRecord::RecordNotFound => error
    Bugnsag.notify(error)
  else
    PullRequestRefresher.new(pull_request).run
  end
end
