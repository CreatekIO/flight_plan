class JobMonitor
  URL_TEMPLATE = 'https://hc-ping.com/%{key}/%{name}'.freeze
  PING_KEY = ENV['HEALTHCHECKS_IO_PING_KEY'].freeze

  class NullInstance
    def start; end
    def done; end
  end

  def self.measure(name)
    instance = new(name)
    instance.start
    yield.tap { instance.done }
  end

  def self.new(name)
    PING_KEY.present? ? super : NullInstance.new
  end

  def initialize(name)
    @name = name
  end

  # https://healthchecks.io/docs/measuring_script_run_time/
  def start
    request("#{name}/start")
  end

  def done
    request(name)
  end

  private

  attr_reader :name

  def request(path)
    connection.get(path)
  rescue => error
    Bugsnag.notify(error)
  end

  def connection
    @connection ||= Faraday.new("https://hc-ping.com/#{PING_KEY}") do |conn|
      conn.options.timeout = 5
      conn.request :retry, max: 5
    end
  end
end
