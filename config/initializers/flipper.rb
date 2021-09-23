require 'flipper/instrumentation/log_subscriber'

FEATURES = Rails.application.config_for(
  :flipper_features,
  env: 'features'
).map { |feature| OpenStruct.new(feature).freeze }.freeze

Flipper.configure do |config|
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
        FEATURES.each { |feature| instance.enable(feature.name) }
      else
        # Just register feature
        FEATURES.each { |feature| instance.add(feature.name) }
      end
    end
  end
end

Flipper::UI.configure do |config|
  config.feature_creation_enabled = false
  config.feature_removal_enabled = false
  config.show_feature_description_in_list = true

  config.descriptions_source = -> (_keys) do
    FEATURES.each_with_object({}) do |feature, descriptions|
      descriptions[feature.name] = feature.description
    end
  end
end
