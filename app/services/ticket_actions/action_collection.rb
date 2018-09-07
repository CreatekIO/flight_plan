class TicketActions::ActionCollection < SortedSet
  TicketActions::ACTION_TYPES.each do |type|
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{type}(text, **options)
        add TicketActions::#{type.to_s.classify}Action.new(text, **options)
      end
    RUBY
  end
end
