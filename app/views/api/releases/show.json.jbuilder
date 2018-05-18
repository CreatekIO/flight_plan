json.release do
  json.id @release.id
  json.title @release.title
  json.repo_releases @release.repo_releases do |repo_release|
    json.id repo_release.id
    json.repo_id repo_release.repo_id
    json.board_tickets repo_release.board_tickets(&:to_builder)
  end
  json.created_at @release.created_at
end
