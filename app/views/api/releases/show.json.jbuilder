json.release do
  json.id @release.id
  json.title @release.title
  json.repo_releases @release.repo_releases
  json.created_at @release.created_at
end
