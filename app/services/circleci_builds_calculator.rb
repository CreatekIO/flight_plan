class CircleciBuildsCalculator
  include Enumerable

  BRANCH_NAMES = %w[master develop].freeze
  CONTEXTS = ['ci/circleci', 'ci/circleci: build'].freeze
  STATES = %w[success failure].freeze

  REPOS = %w[CorporateRewards/myrewards CorporateRewards/redstone].freeze

  Stat = Struct.new(:date, :state, :repo, :count) do
    STATE_ALIASES = { 'success' => 'passed', 'failure' => 'failed' }.freeze

    def success?
      state == 'success'
    end

    def failure?
      state == 'failure'
    end

    def human_state
      STATE_ALIASES.fetch(state)
    end
  end

  def initialize(board, quarter: Quarter.current)
    @board = board
    @quarter = quarter
  end

  def each
    return enum_for(:each) unless block_given?

    quarter.months.each do |date|
      REPOS.each do |repo|
        STATES.each do |state|
          count = builds_for_quarter.fetch([date, state, repo], 0)

          yield Stat.new(date, state, repo, count)
        end
      end
    end
  end

  def builds_for_quarter
    @builds_for_quarter ||= CommitStatus.joins(:repo, :branches).where(
      remote_created_at: quarter.as_time_range,
      context: CONTEXTS,
      state: STATES,
      repos: { remote_url: REPOS },
      branches: { name: BRANCH_NAMES }
    ).group(year_and_month.to_sql, :state, Repo.arel_table[:remote_url]).distinct.count
  end

  private

  attr_reader :board, :quarter

  def year_and_month
    Quarter.calculate_sql(CommitStatus.arel_table[:remote_created_at])
  end
end
