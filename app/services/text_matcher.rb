class TextMatcher
  attr_reader :regex

  class Null < TextMatcher
    def matches?(_)
      false
    end

    def filter(_)
      []
    end
  end

  NULL = Null.new.freeze

  def self.from(object)
    return NULL if object.blank?

    new(Regexp.new(object))
  rescue RegexpError => error
    yield(error) if block_given?

    NULL
  end

  def initialize(regex)
    @regex = regex
  end

  def matches?(object)
    regex.match?(object.to_s)
  end

  def filter(collection)
    collection.grep(regex)
  end
end
