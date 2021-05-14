require 'flipper/instrumentation/log_subscriber'

Flipper.configure do |config|
  features = %i[
    harvest_button
    kpis
    realtime_updates
    self_serve_features
  ]

  config.default do
    redis = Redis.new(url: ENV[ENV['REDIS_PROVIDER'].presence || 'REDIS_URL'])
    namespace = [:flipper, *(Rails.env if Rails.env.test?)].join('/')

    adapter = Flipper::Adapters::Redis.new(
      Redis::Namespace.new(namespace, redis: redis)
    )

    Flipper.new(
      Flipper::Adapters::Instrumented.new(
        adapter,
        instrumenter: ActiveSupport::Notifications
      )
    ).tap do |instance|
      if Rails.env.development?
        # Enable all features for everyone
        features.each { |feature| instance.enable(feature) }
      else
        # Just register feature
        features.each { |feature| instance.add(feature) }
      end
    end
  end
end
