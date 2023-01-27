FROM ruby:2.7.7-alpine3.16

# Should match version of Alpine used in `FROM`
COPY --from=node:18.13.0-alpine3.16 /usr/local/bin/node /usr/local/bin

# Yarn version is that contained in node image above
COPY --from=node:18.13.0-alpine3.16 /opt/yarn-v1.22.19/ /opt/yarn/
# Ensure Yarn executables are in $PATH
RUN ln -s /opt/yarn/bin/yarn /usr/local/bin/yarn && \
  ln -s /opt/yarn/bin/yarnpkg /usr/local/bin/yarnpkg

# hadolint ignore=DL3018
RUN apk upgrade --no-cache --available \
  && apk add --no-cache \
    build-base \
    libstdc++ \
    git \
    tzdata curl \
    postgresql-dev \
    libxml2-dev libxslt-dev \
    chromium

WORKDIR /flight_plan

COPY package.json yarn.lock ./
RUN yarn install && yarn cache clean

COPY Gemfile Gemfile.lock ./
RUN bundle config set force_ruby_platform true && \
  bundle install --jobs "$(getconf _NPROCESSORS_ONLN)"
