class RepoEvent::PullRequestReview < RepoEvent
  def self.import(payload, repo)
    super do |event|
      event.assign_attributes(
        record: repo.pull_request_models.find_by(
          remote_number: payload.dig(:pull_request, :number)
        ),
        action: payload[:action],
        state: payload.dig(:review, :state).try(:downcase),
        branch: payload.dig(:pull_request, :head, :ref),
        sha: payload.dig(:pull_request, :head, :sha),
        url: payload.dig(:review, :html_url)
      )
      yield(event) if block_given?
    end
  end
end
