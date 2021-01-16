class V2Compiler
  include Singleton

  class << self
    delegate :compile, to: :instance
  end

  NODE = Rails.root.join('bin/node14').freeze
  V2_DIR = Rails.root.join('app/javascript/v2').freeze
  WEBPACK_CONFIG = V2_DIR.join('webpack-v2.js').freeze
  WEBPACKER_CONFIG = V2_DIR.join('webpacker-v2.yml').freeze

  PLATFORMS = {
    'x86_64-linux' => 'linux-x64', # Heroku
    'x86_64-linux-musl' => 'alpine-x64' # Docker container
  }.freeze

  def initialize
    @compiling = false
  end

  def compile
    return warn('Already compiling!') if @compiling

    @compiling = true
    download_node_v14
    yarn_install
    run_webpack
  ensure
    @compiling = false
  end

  private

  def download_node_v14
    return if NODE.exist?

    platform = PLATFORMS.fetch(RbConfig['arch']) { raise 'Unsupported platform' }

    system!(
      'curl',
      '--fail',
      '--silent',
      '--show-error',
      '--compressed',
      '--location',
      '--max-time', 5.minutes.to_i,
      '--output', NODE,
      "https://github.com/vercel/pkg-fetch/releases/download/v2.6/uploaded-v2.6-node-v14.4.0-#{platform}"
    )

    FileUtils.chmod('a+x', NODE.to_s, verbose: true)
  end

  def yarn_install
    system!(
      'yarn',
      '--cwd', V2_DIR,
      '--ignore-engines'
    )
  end

  def run_webpack
    run(
      NODE.to_s,
      V2_DIR.join('node_modules/.bin/webpack'),
      '--config', WEBPACK_CONFIG,
      env: {
        'WEBPACKER_CONFIG' => WEBPACKER_CONFIG,
        'RAILS_ENV' => Rails.env,
        'NODE_ENV' => Rails.env
      }
    )
  end

  def run(*args, env: nil)
    debug = args.join(' ')
    puts "== Running #{debug} =="

    cmd = args.map(&:to_s)
    cmd.unshift(env) if env.present?

    Dir.chdir(V2_DIR) do
      Kernel.system(*cmd) or raise "Program failed: #{debug}"
    end
  end
end
