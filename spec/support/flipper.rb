RSpec.configure do |config|
  config.around(:each) do |example|
    if example.metadata[:type] != :system
      original = Flipper.instance
      Flipper.instance = Flipper.new(Flipper::Adapters::Memory.new)

      # Features currently checked server-side
      %i[kpis self_serve_features].each do |feature|
        Flipper.enable(feature)
      end

      example.run

      Flipper.instance = original
    else
      example.run

      Flipper.features.each do |feature|
        Flipper.adapter.clear(feature)
      end
    end
  end
end
