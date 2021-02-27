require 'flipper/instrumentation/log_subscriber'

Flipper.configure do |config|
  features = %i[realtime_updates kpis self_serve_features]

  config.default do
    adapter = if Rails.env.test?
      Flipper::Adapters::Memory.new
    else
      redis = Redis::Namespace.new(
        :flipper,
        redis: Redis.new(url: ENV[ENV['REDIS_PROVIDER'].presence || 'REDIS_URL'])
      )

      Flipper::Adapters::Redis.new(redis)
    end

    Flipper.new(
      Flipper::Adapters::Instrumented.new(
        adapter,
        instrumenter: ActiveSupport::Notifications
      )
    ).tap do |instance|
      if Rails.env.development? || Rails.env.test?
        # Enable all features for everyone
        features.each { |feature| instance.enable(feature) }
      else
        # Just register feature
        features.each { |feature| instance.add(feature) }
      end
    end
  end
end
