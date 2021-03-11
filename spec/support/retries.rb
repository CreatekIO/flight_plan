require 'rspec/retry'

RSpec.configure do |config|
  config.verbose_retry = true
  config.display_try_failure_messages = true

  config.around(:each, js: true) do |example|
    example.run_with_retry(retry: 3)
  end

  config.retry_callback = proc do |example|
    Capybara.reset_sessions! if example.metadata[:js]
  end
end
