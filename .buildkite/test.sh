#!/usr/bin/env sh
set -eu

# For the meaning of the `echo` prefixes, see:
# https://buildkite.com/docs/pipelines/managing-log-output#collapsing-output

buildNumber="${BUILDKITE_BUILD_NUMBER:-0}"
jobCount="${BUILDKITE_PARALLEL_JOB_COUNT:-1}"
jobNumber="${BUILDKITE_PARALLEL_JOB:-0}"

# Shuffles lines from stdin deterministically
# Works by:
# - Generating a random number for each line
# - Prefixing each line with that number and sorting them
# - Removing the random number from each line
# See: https://stackoverflow.com/a/30133294
shuffleLines() {
  awk "BEGIN { srand($buildNumber); OFMT=\"%.17f\" } { print rand(), \$0 }" \
    | sort -k1,1n \
    | cut -d ' ' -f2-
}

pickNthLines() {
  awk "(NR - 1) % $jobCount == $jobNumber { print \$0 }"
}

# https://buildkite.com/docs/pipelines/links-and-images-in-log-output#links
inline_link() {
  link=$(printf "url='%s'" "$1")

  if [ $# -gt 1 ]; then
    link=$(printf "$link;content='%s'" "$2")
  fi

  printf '\033]1339;%s\a\n' "$link"
}

echo "~~~ bundle install"
bundle config set "without" "development"

bundle install \
  --jobs "$(getconf _NPROCESSORS_ONLN)" \
  --retry 2

echo "~~~ yarn install"
yarn install --ignore-engines

echo "~~~ Wait for database"
retries=5

until ruby -rsocket -e 'Socket.tcp(ENV["DB_HOST"], 5432).close' 2>/dev/null; do
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
unset GITHUB_API_TOKEN # prevent this interfering with specs

specsToRun="$(find spec -name '*_spec.rb' | sort | shuffleLines | pickNthLines)"
specsFile=tmp/rspec/files.txt
mkdir -p "$(dirname "$specsFile")"

echo "Will run:"
echo "$specsToRun"

echo "$specsToRun" > "$specsFile"
inline_link "artifact://$specsFile" "Download list of specs run"

xargs bin/rspec \
  --require rspec_junit_formatter \
  --format RspecJunitFormatter \
  --out "tmp/rspec-junit-$BUILDKITE_JOB_ID.xml" \
  --format documentation \
  < "$specsFile"
