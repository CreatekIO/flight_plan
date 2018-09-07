TicketActions::ActionURL = Struct.new(:url, :title) do
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
