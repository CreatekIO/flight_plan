class AddRemoteIdToRepos < ActiveRecord::Migration[5.2]
  class Repo < ActiveRecord::Base; end

  DELETED_REPOS = {
   'CreatekIO/DEPRECATED_ignite2.0-api' => 185486055,
   'CreatekIO/DEPRECATED_ignite2.0-frontend' => 185486172,
  }.freeze

  def change
    add_column :repos, :remote_id, :bigint
    add_index :repos, :remote_id, unique: true

    reversible do |dir|
      dir.up do
        say_with_time "Populating repos.remote_id..." do
          Repo.all.each do |repo|
            remote_id = github_id_for(repo.slug)

            say "Setting remote_id=#{remote_id} for #{repo.slug}"
            repo.update_attributes!(remote_id: remote_id)
          end
        end
      end
    end

    change_column_null :repos, :remote_id, true
  end

  private

  def github_id_for(slug)
    return DELETED_REPOS[slug] if DELETED_REPOS.key?(slug)

    Octokit.repo(slug).id
  rescue Octokit::NotFound
    _, name = slug.split("/", 2)
    new_slug = "360incentives/#{name}"
    return if new_slug == slug # we've already retried

    say "404 for #{slug}, trying #{new_slug}"

    github_id_for(new_slug)
  end
end
