class TicketBlueprint < ApplicationBlueprint
  fields :number, :title
  field :milestone_id, name: :milestone
  field :repo_id, name: :repo

  field :html_url do |ticket, options|
    # Work around the fact we haven't eager-loaded any models
    ticket.repo = options.dig(:records, Repo, ticket.repo_id)
    ticket.html_url
  end

  association_id :display_labels, name: :labels
  association_ids :pull_requests, :assignments

  view :detailed do
    fields :state
    field :creator do |ticket|
      ticket.creator_username || 'ghost'
    end

    field :timestamp do |ticket|
      helpers.time_ago_in_words(ticket.remote_created_at || ticket.created_at)
    end
  end
end
