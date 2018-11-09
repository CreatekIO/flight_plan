class TicketActions::Base
  delegate :html_url, to: :pull_request

  def self.next_actions(&block)
    define_method(:collect_next_actions, &block)
    private :collect_next_actions
  end

  def initialize(pull_request, **config)
    @pull_request = pull_request
    @config = config
  end

  def applies?
    pull_request.open?
  end

  def next_actions(collection = TicketActions::ActionCollection.new)
    collect_next_actions(collection)
    collection
  end

  def next_action
    next_actions.first
  end

  private

  attr_reader :pull_request, :config

  def collect_next_actions
    raise NotImplementedError
  end

  def owner_id
    pull_request.creator_remote_id
  end

  def team_ids(except: [])
    base_team_ids.without(*except)
  end

  def base_team_ids
    # TODO: scope to board/repo
    @base_team_ids ||= User.pluck(:uid).without(owner_id.to_s)
  end
end
