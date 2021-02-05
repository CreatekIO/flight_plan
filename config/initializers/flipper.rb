require 'flipper/instrumentation/log_subscriber'

Flipper.configure do |config|
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
    )
  end
end

Rails.application.config.after_initialize do
  %i[realtime_updates kpis self_serve_features].each do |feature|
    if Rails.env.development? || Rails.env.test?
      # Enable all features for everyone
      Flipper.enable(feature)
    else
      # Just register feature
      Flipper.add(feature)
    end
  end
end
