#!/usr/bin/env sh
set -eu

echo "Installing dependencies..."

if [ -z "$(which chromium-browser)" ]; then
  apk add \
    --no-cache \
    --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community \
    chromium
fi

bundle install \
  --jobs "$(getconf _NPROCESSORS_ONLN)" \
  --retry 2 \
  --without development

yarn install --ignore-engines

echo "Setting up database..."
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

bin/rake db:reset

echo "Compiling assets..."
bin/rake webpacker:compile

echo "Running specs..."
bin/rspec --format documentation
