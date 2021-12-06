#!/usr/bin/env sh
set -eu

echo "~~~ bundle install"
bundle install \
  --jobs "$(getconf _NPROCESSORS_ONLN)" \
  --retry 2 \
  --without development

echo "~~~ yarn install"
yarn install --ignore-engines

echo "~~~ Wait for database"
retries=5

until nc -z "$DB_HOST:5432"; do
  retries="$(("$retries" - 1))"

  if [ "$retries" -eq 0 ]; then
    echo "Failed to reach PostgreSQL" >&2
    exit 1
  fi

  sleep 5
  echo "Waiting for PostgreSQL ($retries retries left)"
done

echo "~~~ rake db:reset"
bin/rake db:reset

echo "~~~ Compiling assets"
bin/rake webpacker:compile

echo "+++ :rspec: Running specs"
bin/rspec --format documentation
