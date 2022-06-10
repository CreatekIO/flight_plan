class ApplicationRule
  extend ActiveSupport::DescendantsTracker
  include ModelListener

  define_callbacks :execute, terminator: -> (_, callback) { !callback.call }

  class_attribute :trigger_classes, instance_writer: false, default: [].freeze
  attr_reader :event

  delegate :flipper_id, to: :class

  set_callback :execute, :feature_enabled?, :enabled_for_board?

  def self.trigger(klass, event, *attrs, &block)
    klass = klass.to_s
    event = :updated if event == :changed
    self.trigger_classes += [klass]

    conditions = [
      proc { record.class.name == klass && self.event == event }
    ]

    if event == :updated
      attrs = attrs.to_set
      conditions << proc { attrs.intersect?(changed_attributes) }
    end

    set_callback(:execute, if: conditions, &block)
  end

  private_class_method :trigger

  def self.alias_record_as(name)
    alias_method name, :record
  end

  private_class_method :alias_record_as

  def self.listen!
    Wisper.subscribe(self, scope: trigger_classes)
  end

  %i[created updated destroyed].each do |event|
    class_eval <<~RUBY, __FILE__, __LINE__ + 1
      def #{event}
        @event = :#{event}
        run_callbacks(:execute) { call }
      end
    RUBY
  end

  def self.flipper_id
    name
  end

  def self.enable!(board, settings = {})
    raise ArgumentError, 'Cannot enable ApplicationRule' if self == ApplicationRule

    BoardRule
      .create_with(settings: settings)
      .find_or_create_by!(board: board, rule_class: name)
      .update_attributes!(enabled: true)
  end

  def call
    raise NotImplementedError
  end

  private

  def move(board_ticket, to:, position: :first)
    return if board_ticket.blank?

    swimlane = board_ticket.board.swimlanes.find_by(name: to)
    return if swimlane.blank?

    board_ticket.update_attributes!(
      swimlane: swimlane,
      swimlane_position: position
    )
  end

  def board_rule
    @board_rule ||= BoardRule.enabled.for(board: board, rule: self.class)
  end

  def halted_callback_hook(filter)
    Rails.logger.info do
      "#{self.class} for #{record.class}##{record.id} failed precondition #{filter.inspect}"
    end
  end

  def feature_enabled?
    Flipper.enabled?(:automation)
  end

  def enabled_for_board?
    board_rule.present? && board_rule.enabled?
  end

  def board
    return @board if defined?(@board)

    @board = if record.is_a?(Board)
      record
    elsif record.respond_to?(:board)
      record.board
    elsif record.respond_to?(:repo)
      record.repo.board
    else
      Rails.logger.warn("Can't find Board for #{record.class}##{record.id}")
      nil
    end
  end
end
