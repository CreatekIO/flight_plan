json.release do
  json.id @release.id
  json.title @release.title
  json.repo_releases @release.repo_releases do |repo_release|
    json.id repo_release.id
    json.repo do
      json.id repo_release.repo.id
      json.name repo_release.repo.name
    end
    json.board_tickets repo_release.board_tickets do |board_ticket|
      json.id board_ticket.id
      json.ticket do
        json.id board_ticket.ticket.id
        json.remote_number board_ticket.ticket.remote_number
        json.remote_title board_ticket.ticket.remote_title
      end
    end
  end
  json.created_at @release.created_at
end
