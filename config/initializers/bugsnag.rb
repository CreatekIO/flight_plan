# API key is set via `BUGSNAG_API_KEY` env variable
Bugsnag.configure do |config|
  config.auto_capture_sessions = true

  # Requires `dyno-metadata` Heroku Labs Feature
  # See:
  # - https://docs.bugsnag.com/build-integrations/heroku/#versioning-heroku-apps
  # - https://devcenter.heroku.com/articles/dyno-metadata
  config.app_version = ENV['HEROKU_RELEASE_VERSION']
end
