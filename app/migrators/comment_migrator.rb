class CommentMigrator < ApplicationMigrator
  rename :remote_body, to: :body
  rename :remote_author_id, to: :author_remote_id
  rename :remote_author, to: :author_username
end
