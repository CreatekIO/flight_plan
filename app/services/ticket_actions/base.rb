class TicketActions::Base
  def initialize(pull_request, **config)
    @pull_request = pull_request
    @config = config
  end

  private

  attr_reader :pull_request, :config

  def next_action
    raise NotImplementedError
  end

  TicketActions::ACTION_TYPES.each do |type|
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{type}(text, urls:)
        TicketActions::#{type.to_s.classify}Action.new(text, urls: urls)
      end
    RUBY
  end
end
