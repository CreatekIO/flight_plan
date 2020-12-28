class RepoMigrator < ApplicationMigrator
  rename :remote_url, to: :slug
end
