FROM ruby:2.4.1-alpine3.6

ENV BUILD_PACKAGES='build-base git \
  mysql-dev postgresql-dev \
  nodejs nodejs-npm \
  tzdata inotify-tools curl \
  libxml2-dev libxslt-dev'

RUN \
  apk add --no-cache --upgrade $BUILD_PACKAGES && \
  npm install --global yarn@1.5.1 && \
  find / -type f -iname \*.apk-new -delete && \
  rm -rf /var/cache/apk/* && \
  rm -rf /usr/lib/lib/ruby/gems/*/cache/*

WORKDIR /flight_plan

COPY package.json yarn.lock ./
RUN yarn install --ignore-engines

COPY Gemfile Gemfile.lock ./
RUN \
  bundle config build.nokogiri --use-system-libraries && \
  bundle install --jobs "$(getconf _NPROCESSORS_ONLN)"
