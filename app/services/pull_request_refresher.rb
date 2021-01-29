class PullRequestRefresher
  include OctokitClient

  delegate :repo, to: :pull_request

  octokit_methods :pull_request, :pull_request_reviews, prefix_with: %w[repo.slug pull_request.number]

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

    octokit_pull_request_reviews.each do |gh_review|
      PullRequestReview.import(
        { review: gh_review.to_hash, pull_request: gh_pull_request },
        repo
      )
    end
  end

  def gh_pull_request
    @gh_pull_request ||= octokit_pull_request.to_hash
  end
end
