json.release do
  json.id @release.id
  json.title @release.title
  json.repo_releases @release.repo_releases do |repo_release|
    json.id repo_release.id
    json.repo repo_release.repo.to_builder
    json.board_tickets repo_release.board_tickets do |board_ticket|
      json.id board_ticket.id
      json.ticket board_ticket.ticket.to_builder
    end
  end
  json.created_at @release.created_at
end
