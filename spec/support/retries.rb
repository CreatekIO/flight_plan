require 'timeout'
require 'rspec/retry'

RSpec.configure do |config|
  config.verbose_retry = true
  config.display_try_failure_messages = true

  config.around(:each, js: true) do |example|
    Timeout.timeout(60) do
      example.run_with_retry(retry: 3)
    end
  end

  config.retry_callback = proc do |example|
    Capybara.reset_sessions! if example.metadata[:js]
  end
end
