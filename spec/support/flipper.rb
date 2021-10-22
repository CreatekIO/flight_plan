RSpec.configure do |config|
  config.around(:each, type: -> (type) { type != :system }) do |example|
    original = Flipper.instance
    Flipper.instance = Flipper.new(Flipper::Adapters::Memory.new)

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
