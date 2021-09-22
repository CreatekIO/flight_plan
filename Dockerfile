# see: https://github.com/docker-library/ruby/blob/master/2.6/alpine3.13/Dockerfile
FROM ruby:2.6.6-alpine3.13

# Should match version of Alpine used in `FROM`
COPY --from=node:14.16.0-alpine3.13 /usr/local/bin/node /usr/local/bin

# Yarn version is that contained in node image above
# see: https://github.com/nodejs/docker-node/blob/master/14/alpine3.13/Dockerfile
COPY --from=node:14.16.0-alpine3.13 /opt/yarn-v1.22.5/ /opt/yarn/
# Ensure Yarn executables are in $PATH
RUN ln -s /opt/yarn/bin/yarn /usr/local/bin/yarn && \
  ln -s /opt/yarn/bin/yarnpkg /usr/local/bin/yarnpkg

RUN apk add --no-cache \
  build-base \
  libstdc++ \
  git \
  tzdata curl \
  postgresql-dev \
  libxml2-dev libxslt-dev

RUN apk add \
  --no-cache \
  --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community \
  chromium

WORKDIR /flight_plan

COPY package.json yarn.lock ./
RUN yarn install

COPY Gemfile Gemfile.lock ./
RUN bundle config build.nokogiri --use-system-libraries && \
  bundle install --jobs "$(getconf _NPROCESSORS_ONLN)"
