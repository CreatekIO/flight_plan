require 'webpacker/dev_server_proxy'
require 'webpacker/version'

# See https://github.com/rails/webpacker/pull/1425
module WebpackerDevServerProxyBackports
  def perform_request(env)
    env['HTTP_X_FORWARDED_PROTO'] = Webpacker.dev_server.protocol
    super(env)
  end
end

major_version = Webpacker::VERSION.split('.').first

raise 'This monkeypatch probably not needed' if Integer(major_version) >= 4

Webpacker::DevServerProxy.include(WebpackerDevServerProxyBackports)
