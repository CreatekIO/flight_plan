module ModelListener
  extend ActiveSupport::Concern
  include ActiveSupport::Callbacks

  included do
    define_callbacks :update
  end

  attr_reader :record
  alias_method :model, :record

  delegate_missing_to :record

  module ClassMethods
    # Wisper interface
    def model_created(record)
      log_errors { new(record).created }
    end

    def model_updated(record, changes)
      log_errors { new(record, changes).updated }
    end

    def model_destroyed(record)
      log_errors { new(record).destroyed }
    end

    private

    def changed(*attrs, **options, &block)
      attrs = attrs.to_set

      options[:if] = [
        proc { attrs.intersect?(changed_attributes) },
        *options[:if]
      ]

      set_callback(:update, *[*options.delete(:call), options], &block)
    end

    def log_errors
      yield
    rescue => error
      Rails.logger.error(
        { class: error.class.name, message: error.message, backtrace: error.backtrace }.to_json
      )
      Bugsnag.notify(error)
    end
  end

  def initialize(record, changes = {})
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
end
