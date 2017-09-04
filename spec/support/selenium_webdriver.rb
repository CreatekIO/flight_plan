Capybara.register_driver :docker_selenium_chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    'chromOptions': {
      'args': %w( headless no-sandbox disable-gpu )
    }
  )

  Capybara::Selenium::Driver.new(
    app, 
    browser: :remote, 
    url: "http://#{ENV['SELENIUM_REMOTE_HOST']}:4444/wd/hub",
    desired_capabilities: capabilities
  )
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :docker_selenium_chrome
  end
end
