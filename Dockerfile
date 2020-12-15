# Use build image first for heavy lifting
FROM ruby:2.6.6-slim

RUN apt-get update \
    && apt-get install -y curl \
    && curl -sL https://deb.nodesource.com/setup_12.x | bash - \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
       apt-transport-https \
       curl \
       git \
       postgresql-client \
       libpq-dev \
       nodejs \
       yarn \
    && rm -rf /var/lib/apt/lists/*

# Add application user
RUN groupadd -r appuser \
    && useradd --system --create-home --gid appuser appuser

# Prepare for Gem builds
RUN apt-get update \
    && apt-get install -y \
       build-essential \
       liblzma-dev \
       patch \
       ruby-dev \
    && gem install bundler --conservative \
    && gem install foreman --conservative

# Everything happens here from now on
WORKDIR /idp-dashboard

COPY Gemfile Gemfile.lock ./
RUN bundle check || bundle install --without deploy production

COPY package.json yarn.lock ./
RUN NODE_ENV=development yarn install --force \
    && yarn cache clean

COPY . ./
RUN bundle exec rails webpacker:install
RUN test -L config/application.yml || cp -v config/application.yml.example config/application.yml

EXPOSE 3001

CMD ["foreman", "start", "-p", "3001"]
