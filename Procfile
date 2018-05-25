web: bin/rails server -p $PORT -e $RAILS_ENV
worker: bundle exec sidekiq
clockwork: bundle exec clockwork clock.rb
release: bin/rake db:migrate
