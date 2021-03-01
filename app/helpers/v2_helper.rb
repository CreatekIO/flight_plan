module V2Helper
  DEVELOPMENT_HOST = 'https://webpack.dev.createk.io'.freeze

  class << self
    attr_accessor :v2_manifest
  end

  def v2_javascripts(entrypoint)
    javascript_include_tag(
      *v2_assets.fetch(entrypoint.to_s).fetch('assets')['js'],
      host: v2_host
    )
  end

  def v2_stylesheets(entrypoint)
    stylesheet_link_tag(
      *v2_assets.fetch(entrypoint.to_s).fetch('assets')['css'],
      host: v2_host,
      media: 'all'
    )
  end

  private

  def v2_host
    Rails.env.production? ? nil : DEVELOPMENT_HOST
  end

  def v2_assets
    if Rails.env.production?
      V2Helper.v2_manifest ||= load_v2_manifest
    else
      load_v2_manifest
    end
  end

  def load_v2_manifest
    JSON.parse(
      Rails.root.join('public/packs-v2/manifest.json').read
    ).fetch('entrypoints')
  end
end
