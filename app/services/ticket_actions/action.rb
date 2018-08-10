class TicketActions::Action
  include Comparable

  attr_reader :text, :urls, :priority, :user_ids

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

  def initialize(text, urls:, priority: 0, user_ids: [])
    @text = text
    self.urls = urls
    @priority = priority
    self.user_ids = user_ids
  end

  def <=>(other)
    sort_key <=> other.sort_key
  end

  def ==(other)
    self.class == other.class && \
      instance_values.except('priority') == other.instance_values.except('priority')
  end

  def urls=(value)
    @urls = Array.wrap(value).map {|obj| URL.from(obj) }
  end

  def url
    urls.first
  end

  def user_ids=(value)
    @user_ids = Array.wrap(value).map(&:to_s).to_set
  end

  def applies_to?(user_id)
    return true if user_ids.empty?

    user_ids.include?(user_id.to_s)
  end

  def sort_key
    [-priority, TicketActions::ACTION_TYPES.index(type)]
  end
end
