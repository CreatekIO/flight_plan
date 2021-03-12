require 'capybara/cuprite'

Capybara.javascript_driver = :cuprite

Capybara.register_driver(:cuprite) do |app|
  options = {
    window_size: [1200, 800],
    timeout: 10,
    # logger: $stderr, # uncomment for debugging logs
    js_errors: true,
    browser_options: {
      'no-sandbox' => nil, # needed as we run as root inside Docker
      # 'auto-open-devtools-for-tabs' => nil # uncomment to open devtools
    },
    url_whitelist: [%r{^https?://(localhost|127\.0\.0\.1)}]
  }

  # Instructions here for macOS:
  #   https://medium.com/@mreichelt/how-to-show-x11-windows-within-docker-on-mac-50759f4b65cb
  #
  # Briefly:
  # 1. Install XQuartz
  # 2. Ensure network connections are allowed
  # 3. Open XQuartz.app
  # 4. Allow connections from localhost: `xhost + 127.0.0.1` (think you have to do this every time)
  if ENV['CHROMIUM_MODE'] == 'x11'
    ENV['DISPLAY'] = 'host.docker.internal:0'
    options[:headless] = false
  end

  Capybara::Cuprite::Driver.new(app, options)
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :cuprite
  end
end
