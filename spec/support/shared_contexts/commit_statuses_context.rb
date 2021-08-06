RSpec.shared_context 'commit statuses' do
  class StatusWrapper < SimpleDelegator
    def initialize(attrs)
      super FactoryBot.create(:commit_status, attrs)
    end

    def present?
      CommitStatus.exists?(id: id)
    end

    def destroyed?
      !present?
    end

    alias_method :blank?, :destroyed?
  end

  class Commit
    attr_reader :statuses

    def self.global_base_time
      @now ||= Time.now
    end

    def self.repos
      @repo_count ||= 0

      @repos ||= Hash.new do |cache, name|
        @repo_count += 1

        cache[name] = FactoryBot.create(
          :repo,
          name: name,
          slug: "CreatekIO/#{name}",
          remote_id: 200_000_000 + @repo_count
        )
      end
    end

    def initialize(scenario_text)
      @sha = FactoryBot.generate(:sha)
      base_time = nil

      @statuses = scenario_text.split("\n").map.each_with_index do |line, index|
        state, time, service, repo = line.split(/\s+/, 4)
        service ||= 'circleci'
        repo ||= 'flight_plan'
        time_ago = Integer(time.presence || 0).minutes

        created_at = if index.zero?
          base_time = self.class.global_base_time + time_ago
        else
          base_time + time_ago
        end

        StatusWrapper.new(
          repo: self.class.repos[repo],
          state: state,
          sha: @sha,
          context: service,
          remote_created_at: created_at
        )
      end
    end
  end

  def self.generate_scenario(name, text)
    let!(name) { Commit.new(text) }
  end
end
