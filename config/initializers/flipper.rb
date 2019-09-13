require 'flipper/instrumentation/log_subscriber'

Flipper.configure do |config|
  config.default do
    Flipper.new(
      Flipper::Adapters::Instrumented.new(
        Flipper::Adapters::Redis.new(
          Redis.new(url: ENV[ENV['REDIS_PROVIDER'].presence || 'REDIS_URL'])
        ),
        instrumenter: ActiveSupport::Notifications
      )
    )
  end
end
