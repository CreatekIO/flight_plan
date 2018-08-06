class TicketActions
  ALL_ACTIONS = %w[
    PullRequestStatuses
    Mergeability
    PullRequestReviews
  ].freeze

  def self.for(pull_request, actions: ALL_ACTIONS, user: nil)
    actions.each_with_object(SortedSet.new) do |klass, collection|
      check = const_get(klass).new(pull_request)
      action = check.next_action
      next if action.blank?

      collection.add(action)
    end
  end

  # In order of severity, worst to best
  ACTION_TYPES = [:negative, :warning, :neutral, :positive].freeze

  class Action
    attr_reader :text, :urls
    include Comparable

    delegate :type, to: :class

    def self.type
      @type ||= name.demodulize.remove('Action').underscore.to_sym
    end

    def initialize(text, urls:)
      @text = text
      self.urls = urls
    end

    def <=>(other)
      ACTION_TYPES.index(type) <=> ACTION_TYPES.index(other.type)
    end

    def ==(other)
      self.class == other.class && instance_values == other.instance_values
    end

    def urls=(value)
      @urls = Array.wrap(value)
    end

    def url
      urls.first
    end
  end

  private_constant :Action

  ACTION_TYPES.each do |type|
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      class #{type.to_s.classify}Action < Action; end
    RUBY
  end
end
