class RepoEvent::PullRequestReview < RepoEvent
  def self.import(payload, _repo)
    super do |event|
      event.assign_attributes(
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
