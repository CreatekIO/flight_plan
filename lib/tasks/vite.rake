namespace :vite do
  # Uses NPM and is a prerequisite of `assets:precompile`, so we disable it
  # See https://github.com/ElMassimo/vite_ruby/pull/217#issuecomment-1200931112
  task(:install_dependencies).clear
end
