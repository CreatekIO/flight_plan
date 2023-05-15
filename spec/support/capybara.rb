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
  case ENV['CHROMIUM_MODE']
  when 'x11'
    ENV['DISPLAY'] = 'host.docker.internal:0'
    options[:headless] = false
  when 'host'
    require 'resolv'

    host_ip = Resolv.getaddress('host.docker.internal')
    options[:url] = "http://#{host_ip}:9222"

    WebMock.disable_net_connect!(
      allow_localhost: true,
      allow: "#{host_ip}:9222"
    )
    Capybara.server_host = '0.0.0.0'
    Capybara.server_port = 31000
  end

  Capybara::Cuprite::Driver.new(app, options)
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    # `using: :chrome` (the default) errors because Rails tries to use selenium-webdriver
    driven_by :cuprite, using: :cuprite

    @fp_debug_thread = Thread.new do
      Thread.current.abort_on_exception = true

      sleep 30

      # Taken from sidekiq
      Thread.list.each do |thread|
        Rails.logger.warn "#{thread.object_id} #{thread.name}"
        puts "#{thread.object_id} #{thread.name}"
        $stdout.flush

        if thread.backtrace
          Rails.logger.warn thread.backtrace.join("\n")
          puts thread.backtrace.join("\n")
          $stdout.flush
        else
          Rails.logger.warn "<no backtrace available>"
          puts "<no backtrace available>"
          $stdout.flush
        end
      end
    end
  end

  config.after(:each, type: :system, js: true) do
    begin
      if defined?(@fp_debug_thread)
        @fp_debug_thread.kill
        @fp_debug_thread.join
      end
    rescue => error
      Rails.logger.error(error.inspect)
      p error
      puts error.backtrace.join("\n")
      $stdout.flush
    end
  end
end
