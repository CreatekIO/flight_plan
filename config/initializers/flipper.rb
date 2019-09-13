require 'flipper/instrumentation/log_subscriber'

Flipper.configure do |config|
  config.default do
    redis = Redis::Namespace.new(
      :flipper,
      redis: Redis.new(url: ENV[ENV['REDIS_PROVIDER'].presence || 'REDIS_URL'])
    )

    Flipper.new(
      Flipper::Adapters::Instrumented.new(
        Flipper::Adapters::Redis.new(redis),
        instrumenter: ActiveSupport::Notifications
      )
    )
  end
end
