web: bin/rails server -p $PORT -e $RAILS_ENV
worker: bundle exec sidekiq
clockwork: bundle exec clockwork clock.rb
# Run as two separate processes to clear out Rails' migration caches
release: bin/rake db:migrate && bin/rake db:data:migrate
