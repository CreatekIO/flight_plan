Rake::Task['assets:precompile'].enhance do
  cp_r(
    Rails.root.join('node_modules', 'semantic-ui-css', 'themes'),
    Rails.root.join('public', 'assets')
  )
end

namespace :v2 do
  task compile: :environment do
    V2Compiler.compile
  end
end

# Run `v2:compile` after compiling other assets
Rake::Task['assets:precompile'].enhance do
  Rake::Task['v2:compile'].invoke
end
