RSpec.configure do |config|
  config.around(:each) do |example|
    original = Flipper.instance

    unless example.metadata[:type] == :system
      Flipper.instance = Flipper.new(
        Flipper::Adapters::Instrumented.new(
          Flipper::Adapters::Memory.new,
          instrumenter: ActiveSupport::Notifications
        )
      )
    end

    example.run

    Flipper.instance = original
  end

  config.before(:each) do
    # Ensure "default" features are always enabled
    ::FEATURES.select(&:default).map(&:name).each do |feature|
      Flipper.enable(feature)
    end
  end

  config.after(:each, type: :system) do
    Flipper.features.each do |feature|
      Flipper.adapter.clear(feature)
    end
  end
end
