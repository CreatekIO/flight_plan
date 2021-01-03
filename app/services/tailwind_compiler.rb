class TailwindCompiler
  include Singleton

  class << self
    delegate :compile, to: :instance
  end

  NODE = Rails.root.join('bin/node14').freeze
  OUTPUT_CSS_FILE = Rails.root.join('app/assets/stylesheets/tailwind.css').freeze
  V2_DIR = Rails.root.join('app/javascript/v2').freeze

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
    run_tailwind_cli
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

  def run_tailwind_cli
    env = {}
    env['NODE_ENV'] = 'production' if Rails.env.production?

    system!(
      NODE.to_s,
      V2_DIR.join('node_modules/.bin/tailwind'),
      'build',
      '-o', OUTPUT_CSS_FILE,
      env: env
    )
  end

  def system!(*args, env: nil)
    debug = args.join(' ')
    puts "== Running #{debug} =="

    cmd = args.map(&:to_s)
    cmd.unshift(env) if env.present?

    Kernel.system(*cmd) or raise "Program failed: #{debug}"
  end
end
