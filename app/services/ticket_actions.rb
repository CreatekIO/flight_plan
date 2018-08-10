class TicketActions
  ALL_ACTIONS = %w[
    PullRequestStatuses
    Mergeability
    PullRequestReviews
  ].freeze

  DEFAULT_CONFIG = {
    'PullRequestStatuses' => {
      ignored_contexts: %w[codeclimate]
    }
  }.freeze

  def self.for(pull_request, actions: ALL_ACTIONS)
    actions.each_with_object(SortedSet.new) do |klass, collection|
      check_class = const_get(klass)
      config = DEFAULT_CONFIG.fetch(klass, {})
      check = check_class.new(pull_request, config)
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

    URL = Struct.new(:url, :title) do
      delegate :to_s, :to_str, to: :url

      def self.from(*value)
        return new(*value) if value.size == 2
        value = value.first

        case value
        when self
          value
        when String
          new(value)
        when Array
          new(*value)
        when Hash
          new(*value.symbolize_keys.values_at(:url, :title))
        else
          new(value.to_s)
        end
      end
    end

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
      @urls = Array.wrap(value).map {|obj| URL.from(obj) }
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
