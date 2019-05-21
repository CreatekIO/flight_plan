class PullRequestRefresher
  include OctokitClient

  delegate :repo, :remote_number, to: :pull_request
  delegate :remote_url, to: :repo

  octokit_methods :pull_request, :pull_request_reviews, prefix_with: %i[remote_url remote_number]
  alias_method :get_pull_request, :pull_request

  def initialize(pull_request)
    @pull_request = pull_request
  end

  def run
    update_pull_request
    update_reviews
  end

  private

  attr_reader :pull_request

  def update_pull_request
    @pull_request = PullRequest.import(gh_pull_request, repo)
  end

  def update_reviews
    return if gh_pull_request[:state] == 'closed'

    pull_request_reviews.each do |gh_review|
      PullRequestReview.import(
        { review: gh_review.to_hash, pull_request: gh_pull_request },
        repo
      )
    end
  end

  def gh_pull_request
    @gh_pull_request ||= get_pull_request.to_hash
  end
end
