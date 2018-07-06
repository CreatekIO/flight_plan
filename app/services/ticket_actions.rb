class TicketActions
  # In order of severity, worst to best
  ACTION_TYPES = [:negative, :warning, :neutral, :positive].freeze

  class Action
    attr_reader :text, :urls

    delegate :type, to: :class

    def self.type
      @type ||= name.demodulize.remove('Action').underscore.to_sym
    end

    def initialize(text, urls:)
      @text = text
      self.urls = urls
    end

    def ==(other)
      self.class == other.class && instance_values == other.instance_values
    end

    def urls=(value)
      @urls = Array.wrap(value)
    end
  end

  private_constant :Action

  ACTION_TYPES.each do |type|
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      class #{type.to_s.classify}Action < Action; end
    RUBY
  end
end
