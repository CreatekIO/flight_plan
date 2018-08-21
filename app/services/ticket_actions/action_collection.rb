class TicketActions::ActionCollection < SortedSet
  TicketActions::ACTION_TYPES.each do |type|
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{type}(text, **options)
        add_action('#{type}', text, **options)
      end
    RUBY
  end

  def caution(text, **options)
    options[:for_other_user] = true
    add_action('warning', text, **options)
  end

  private

  def add_action(type, text, **options)
    klass = "TicketActions::#{type.classify}Action".constantize

    add klass.new(text, **options)
  end
end
