Rake::Task['assets:precompile'].enhance do
  cp_r(
    Rails.root.join('node_modules', 'semantic-ui-css', 'themes'),
    Rails.root.join('public', 'assets')
  )
end

namespace :tailwind do
  task compile: :environment do
    TailwindCompiler.compile
  end
end

# Run `tailwind:compile` before compiling other assets
Rake::Task['assets:precompile'].enhance(%w[tailwind:compile])
