module TicketActionHelpers
  %w[positive neutral warning negative].each do |type|
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def be_a_#{type}_action(*args)
        eq(TicketActions::#{type.classify}Action.new(*args))
      end
    RUBY
  end
end

RSpec.configure do |config|
  config.include TicketActionHelpers, type: :ticket_action
end
