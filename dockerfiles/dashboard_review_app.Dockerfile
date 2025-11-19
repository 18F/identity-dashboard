FROM ruby:3.4.5-slim

# Set environment variables
ENV RAILS_ROOT /dashboard
ENV RAILS_ENV production
ENV NODE_ENV production
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true
ENV LOGIN_CONFIG_FILE $RAILS_ROOT/tmp/application.yml
ENV RAILS_LOG_LEVEL debug
ENV BUNDLE_PATH /usr/local/bundle
ENV PIDFILE /tmp/server.pid
ENV NODE_VERSION 22.12.0
ENV BUNDLER_VERSION 2.6.9

ENV POSTGRES_SSLMODE prefer
ENV POSTGRES_DB dashboard
ENV POSTGRES_HOST localhost
ENV POSTGRES_USERNAME postgres
ENV POSTGRES_PASSWORD password
ENV POSTGRES_SSLCERT /usr/local/share/aws/rds-combined-ca-bundle.pem
ENV NEW_RELIC_ENABLED false

ENV DASHBOARD_API_TOKEN changeme

ENV IDP_SP_URL  http://localhost:3000
ENV IDP_URL http://localhost:3000

ENV POST_LOGOUT_URL http://localhost:3000
ENV SAML_SP_ISSUER http://localhost:3001
ENV MAILER_DOMAIN https://dashboard.login.gov
ENV LOGIN_DOMAIN identitysandbox.gov

ENV NEW_RELIC_LICENSE_KEY changeme

# Prevent documentation installation
RUN echo 'path-exclude=/usr/share/doc/*' > /etc/dpkg/dpkg.cfg.d/00_nodoc && \
    echo 'path-exclude=/usr/share/man/*' >> /etc/dpkg/dpkg.cfg.d/00_nodoc && \
    echo 'path-exclude=/usr/share/groff/*' >> /etc/dpkg/dpkg.cfg.d/00_nodoc && \
    echo 'path-exclude=/usr/share/info/*' >> /etc/dpkg/dpkg.cfg.d/00_nodoc && \
    echo 'path-exclude=/usr/share/lintian/*' >> /etc/dpkg/dpkg.cfg.d/00_nodoc && \
    echo 'path-exclude=/usr/share/linda/*' >> /etc/dpkg/dpkg.cfg.d/00_nodoc

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    git-core \
    gnupg \
    curl \
    zlib1g-dev \
    build-essential \
    libssl-dev \
    libreadline-dev \
    libyaml-dev \
    libsqlite3-dev \
    sqlite3 \
    libxml2-dev \
    libxslt1-dev \
    libcurl4-openssl-dev \
    libffi-dev \
    libpq-dev \
    unzip && \
    rm -rf /var/lib/apt/lists/*

# Download RDS Combined CA Bundle
RUN mkdir -p /usr/local/share/aws \
  && curl https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem > /usr/local/share/aws/rds-combined-ca-bundle.pem \
  && chmod 644 /usr/local/share/aws/rds-combined-ca-bundle.pem

RUN curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
  && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && rm "node-v$NODE_VERSION-linux-x64.tar.xz" \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejsv

RUN mkdir -p /usr/local/share/aws \
    && cd /usr/local/share/aws \
    && curl -fsSLk https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem --output rds-combined-ca-bundle.pem

# Create a new user and set up the working directory
RUN addgroup --gid 1000 app && \
    adduser --uid 1000 --gid 1000 --disabled-password --gecos "" app && \
    mkdir -p $RAILS_ROOT && \
    mkdir -p $BUNDLE_PATH && \
    mkdir -p $RAILS_ROOT/tmp/pids && \
    mkdir -p $RAILS_ROOT/log

# Setup timezone data
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone


WORKDIR $RAILS_ROOT

COPY .ruby-version $RAILS_ROOT/.ruby-version
COPY Gemfile $RAILS_ROOT/Gemfile
COPY Gemfile.lock $RAILS_ROOT/Gemfile.lock

COPY ./app ./app
COPY ./bin ./bin
COPY ./config ./config
COPY ./db ./db
COPY ./lib ./lib
COPY ./public ./public
COPY ./spec ./spec
COPY ./config.ru ./config.ru
COPY ./Rakefile ./Rakefile
COPY ./Rakefile ./Rakefile
COPY ./Procfile ./Procfile
COPY ./babel.config.js ./babel.config.js
COPY ./webpack.config.js ./webpack.config.js
COPY ./.browserslistrc ./.browserslistrc

COPY ./config/application.yml.default.review_app $RAILS_ROOT/config/application.yml
COPY ./config/newrelic.yml.docker $RAILS_ROOT/config/newrelic.yml
COPY ./config/database.yml.docker $RAILS_ROOT/config/database.yml

RUN bundle config unset deployment
RUN bundle config build.nokogiri --use-system-libraries
RUN bundle config set --local deployment 'true'
RUN bundle config set --local path $BUNDLE_PATH
RUN bundle config set --local without 'deploy development test'
RUN bundle install
RUN bundle binstubs --all

COPY package.json $RAILS_ROOT/package.json
COPY package-lock.json $RAILS_ROOT/package-lock.json
RUN npm install --cache=.cache/npm

# Generate and place SSL certificates for puma
RUN mkdir -p $RAILS_ROOT/keys
RUN openssl req -x509 -sha256 -nodes -newkey rsa:2048 -days 1825 \
    -keyout $RAILS_ROOT/keys/localhost.key \
    -out $RAILS_ROOT/keys/localhost.crt \
    -subj "/C=US/ST=Fake/L=Fakerton/O=Dis/CN=localhost" && \
    chmod 644 $RAILS_ROOT/keys/localhost.key $RAILS_ROOT/keys/localhost.crt

# Create PID folder in /tmp for server pid
RUN mkdir -m 666 /tmp/pids

# Precompile assets
RUN bundle exec rake assets:precompile --trace

# remove build-essential
RUN apt autoremove -y --purge build-essential

# make everything the proper perms after everything is initialized
RUN chown -R app:app $RAILS_ROOT/tmp && \
    chown -R app:app $RAILS_ROOT/log && \
    find $RAILS_ROOT -type d | xargs chmod 755

# Set user
USER app

EXPOSE 3001

CMD ["bundle", "exec", "puma", "-b", "ssl://0.0.0.0:3001?key=/dashboard/keys/localhost.key&cert=/dashboard/keys/localhost.crt"]
