class PullRequestMigrator < ApplicationMigrator
  %i[number title body state head_branch head_sha base_branch].each do |column|
    rename :"remote_#{column}", to: column
  end
end
