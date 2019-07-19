require 'puma/events'

module WebhookTestCase
  extend ActiveSupport::Concern

  class Events < Puma::Events
    attr_reader :parent_thread

    def initialize(parent_thread)
      @parent_thread = parent_thread
      super(STDOUT, STDERR)
    end

    def parse_error(*args)
      parent_thread.raise args.last
    end

    def unknown_error(_server, error, *)
      parent_thread.raise error
    end
  end

  module ClassMethods
    def event_type(event, &block)
      let(:event_type) { event }

      context("`#{event}` event", &block)
    end

    def action(name, &block)
      context("`#{name}` action", &block)
    end
  end

  included do
    include Rails.application.routes.url_helpers

    around(:all) do |each|
      begin
        puma = start_server!
        each.run
      ensure
        puma.stop if defined?(puma)
      end
    end

    before do
      DatabaseCleaner.strategy = [:truncation, pre_count: true]
    end

    around do |example|
      begin
        WebMock.disable_net_connect!(allow_localhost: true)
        example.run
        WebMock.disable_net_connect!
      end
    end
  end

  def start_server!
    Puma::Server.new(Rails.application, Events.new(Thread.current)).tap do |server|
      server.min_threads = 1
      server.add_tcp_listener('localhost', puma_port)
      server.run
    end
  end

  def puma_port
    @puma_port ||=
      begin
        server = TCPServer.new('localhost', 0)
        server.addr[1]
      ensure
        server.close if defined?(server)
      end
  end

  def webhook_secret
    raise NotImplementedError
  end

  def deliver_webhook(payload, event: event_type)
    fake = GithubWebhookFake.new(webhook_github_url(host: "http://localhost:#{puma_port}"))

    fake.deliver(event: event, payload: payload, secret: webhook_secret)
  end
end

RSpec.configure do |config|
  config.include WebhookTestCase, type: :webhook
end
