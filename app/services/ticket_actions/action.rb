class TicketActions::Action
  include Comparable

  attr_reader :text, :urls, :user_ids

  delegate :type, to: :class

  DEFAULT_PRIORITIES = {
    negative: 100
  }.freeze

  def self.type
    @type ||= name.demodulize.remove('Action').underscore.to_sym
  end

  def initialize(text, **options)
    @text = text
    @user_ids = Set.new

    options.each do |key, value|
      send("#{key}=", value)
    end
  end

  def <=>(other)
    sort_key <=> other.sort_key
  end

  def ==(other)
    self.class == other.class && \
      instance_values.except('priority') == other.instance_values.except('priority')
  end

  def urls=(value)
    @urls = Array.wrap(value).map do |obj|
      TicketActions::ActionURL.from(obj)
    end
  end

  def url
    urls.first
  end

  def user_ids=(value)
    @user_ids = Array.wrap(value).map(&:to_s).to_set
  end

  def priority
    @priority ||= DEFAULT_PRIORITIES.fetch(type, 0)
  end

  def for_other_user?
    type == :caution
  end

  def applies_to?(user_id)
    return true if user_ids.empty?

    user_ids.include?(user_id.to_s)
  end

  def sort_key
    [-priority, TicketActions::ACTION_TYPES.index(type)]
  end

  def as_json(options = nil)
    {
      type: type,
      text: text,
      urls: urls.as_json
    }.as_json(options)
  end

  private

  attr_writer :text, :priority
end
