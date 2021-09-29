class PullRequestBlueprint < ApplicationBlueprint
  fields :number, :title, :state, :merged
  field :repo_id, name: :repo

  field :html_url do |pull_request, options|
    # Work around the fact we haven't eager-loaded any models
    pull_request.repo = options.dig(:records, Repo, pull_request.repo_id)
    pull_request.html_url
  end
end
