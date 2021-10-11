class ApplicationBroadcast
  include ActiveSupport::Callbacks

  thread_cattr_accessor :suppressed, instance_writer: false

  attr_reader :record, :event
  alias_method :model, :record

  delegate_missing_to :record

  define_callbacks :update

  def self.suppressed?
    current = self

    loop do
      break true if current.suppressed
      break false if current == ApplicationBroadcast

      current = current.superclass
    end
  end

  def self.suppress
    self.suppressed = true
    yield
  ensure
    self.suppressed = nil
  end

  def self.changed(*attrs, **options, &block)
    attrs = attrs.to_set

    options[:if] = [
      proc { attrs.intersect?(changed_attributes) },
      *options[:if]
    ]

    set_callback(:update, *[*options.delete(:call), options], &block)
  end

  private_class_method :changed

  def self.inherited(klass)
    super

    model_key = klass.name.remove(/Broadcast$/).underscore
    klass.alias_method model_key, :record
  end

  # Wisper interface
  %i[created updated destroyed].each do |event|
    class_eval <<~RUBY, __FILE__, __LINE__ + 1
      def self.model_#{event}(record, *args)
        return if suppressed?

        new(record, *args).#{event}
      rescue => error
        Rails.logger.error("\#{self} (#{event}) error: \#{error.inspect}")
        Rails.logger.error(error.backtrace.join("\\n"))
        Bugsnag.notify(error)
      end
    RUBY
  end

  def initialize(record, changes = nil)
    @record = record
    @recorded_changes = changes
  end

  def created; end
  def destroyed; end

  def updated
    run_callbacks(:update)
  end

  private

  attr_reader :recorded_changes

  def changed_attributes
    @changed_attributes ||= recorded_changes.keys.map(&:to_sym).to_set
  end

  def blueprint(model, *args)
    "#{model.class}Blueprint".constantize.render_as_hash(model, *args)
  end

  def broadcast_to_board(event, payload, board: record.board)
    broadcast_to_model(board, event, payload)
  end

  def broadcast_change(record, attribute, to:)
    payload = {
      ReduxLoader.to_key(record) => {
        record.id => {
          id: record.id,
          ReduxLoader.to_key(attribute) => record.send(attribute)
        }
      }
    }

    event = "#{record.model_name.param_key}/#{attribute}_changed"
    broadcast_to_model(to, event, payload)
  end

  def broadcast_to_model(model, event, payload)
    payload = payload.transform_keys { |key| ReduxLoader.to_key(key) } if payload.is_a?(Hash)

    "#{model.class}Channel".constantize.broadcast_to(
      model,
      type: "ws/#{event}",
      meta: { userId: nil }, # FIXME
      payload: payload
    )
  end
end
