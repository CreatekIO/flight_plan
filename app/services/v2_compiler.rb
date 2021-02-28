class V2Compiler
  include Singleton

  class << self
    delegate :compile, to: :instance
  end

  V2_DIR = Rails.root.join('app/javascript/v2').freeze
  WEBPACK_CONFIG = V2_DIR.join('webpack-v2.js').freeze
  WEBPACKER_CONFIG = V2_DIR.join('webpacker-v2.yml').freeze

  def initialize
    @compiling = false
  end

  def compile
    return warn('Already compiling!') if @compiling

    @compiling = true
    yarn_install
    run_webpack
  ensure
    @compiling = false
  end

  private

  def yarn_install
    system!('yarn', '--ignore-engines')
  end

  def run_webpack
    system!(
      V2_DIR.join('node_modules/.bin/webpack'),
      '--config', WEBPACK_CONFIG,
      env: {
        'WEBPACKER_CONFIG' => WEBPACKER_CONFIG,
        'RAILS_ENV' => Rails.env,
        'NODE_ENV' => Rails.env
      }
    )
  end

  def system!(*args, env: nil)
    debug = args.join(' ')
    puts "== Running #{debug} =="

    cmd = args.map(&:to_s)
    cmd.unshift(env.transform_values(&:to_s)) if env.present?

    Dir.chdir(V2_DIR) do
      Kernel.system(*cmd) or raise "Program failed: #{debug}"
    end
  end
end
