class ReparseInterRepoConnectsInPullRequestBodies < ActiveRecord::Migration["4.2"]
  def up
    # This will include some false positives, but that won't matter as we won't
    # make any changes to them
    PullRequest.where(
      'remote_body COLLATE utf8mb4_general_ci REGEXP \'connect[^\r\n]+/[^\r\n]+#\''
    ).each do |pull_request|
      say_with_time "Updating PR ##{pull_request.id}" do
        pull_request.save!
      end
    end
  end
end
