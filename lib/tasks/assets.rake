Rake::Task['assets:precompile'].enhance do
  cp_r(
    Rails.root.join('node_modules', 'semantic-ui-css', 'themes'),
    Rails.root.join('public', 'assets')
  )
end
