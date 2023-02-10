FROM ruby:2.7.7-slim

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    curl \
    gcc \
    libpq-dev \
    make \
    chromium \
  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# hadolint ignore=DL3008
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
  curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /usr/share/keyrings/yarn.gpg >/dev/null && \
  echo "deb [signed-by=/usr/share/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian stable main" | tee /etc/apt/sources.list.d/yarn.list && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    nodejs \
    yarn \
  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /flight_plan

COPY package.json yarn.lock ./
RUN yarn install --ignore-engines && yarn cache clean

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs "$(getconf _NPROCESSORS_ONLN)"
