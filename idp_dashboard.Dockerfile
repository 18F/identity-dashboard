FROM ruby:3.2.2-slim

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
ENV YARN_VERSION 1.22.19
ENV NODE_VERSION 18.16.1
ENV BUNDLER_VERSION 2.4.4

ENV POSTGRES_SSLMODE prefer 
ENV POSTGRES_DB dashboard
ENV POSTGRES_HOST localhost
ENV POSTGRES_USERNAME postgres
ENV POSTGRES_PASSWORD password
ENV POSTGRES_SSLCERT /usr/local/share/aws/rds-combined-ca-bundle.pem
ENV NEW_RELIC_ENABLED false


ENV SMPT_HOST changeme
ENV SMPT_PASSWORD changeme
ENV SMPT_PORT 2025
ENV SMPT_USERNAME changeme

ENV DASHBOARD_API_TOKEN changeme

ENV IDP_SP_URL  http://localhost:3000
ENV IDP_URL http://localhost:3000

ENV LOGO_UPLOAD_ENABLED false
ENV POST_LOGOUT_URL http://localhost:3000
ENV SAML_SP_ISSUER http://localhost:3001
ENV SMPT_ADDRESS changeme
ENV SMPT_DOMAIN   changeme
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

# Create a new user and set up the working directory
RUN addgroup --gid 1000 app && \
    adduser --uid 1000 --gid 1000 --disabled-password --gecos "" app && \
    mkdir -p $RAILS_ROOT && \
    mkdir -p $BUNDLE_PATH && \
    chown -R app:app $RAILS_ROOT && \
    chown -R app:app $BUNDLE_PATH

# Setup timezone data
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone


# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    git-core \
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
    software-properties-common \
    libffi-dev \
    libpq-dev \
    unzip && \
    rm -rf /var/lib/apt/lists/*



RUN curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
  && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && rm "node-v$NODE_VERSION-linux-x64.tar.xz" \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejsv

# Install Yarn
#RUN curl -sSk https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /usr/share/keyrings/yarn-archive-keyring.gpg >/dev/null
#RUN echo "deb [signed-by=/usr/share/keyrings/yarn-archive-keyring.gpg] https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
#RUN apt-get update && apt-get install -y yarn=1.22.5-1
RUN curl -fsSLO --compressed "https://github.com/yarnpkg/yarn/releases/download/v$YARN_VERSION/yarn_1.22.19_all.deb" \
  && dpkg --install "yarn_1.22.19_all.deb" \
  && rm "yarn_1.22.19_all.deb" 
  
RUN mkdir -p /usr/local/share/aws \
    && cd /usr/local/share/aws \
    && curl -fsSLk https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem --output rds-combined-ca-bundle.pem
WORKDIR $RAILS_ROOT

# Set user
USER app



COPY .ruby-version $RAILS_ROOT/.ruby-version
COPY Gemfile $RAILS_ROOT/Gemfile
COPY Gemfile.lock $RAILS_ROOT/Gemfile.lock

COPY --chown=app:app ./app ./app
COPY --chown=app:app ./bin ./bin
COPY --chown=app:app ./config ./config
COPY --chown=app:app ./db ./db
COPY --chown=app:app ./lib ./lib
COPY --chown=app:app ./public ./public
COPY --chown=app:app ./spec ./spec
COPY --chown=app:app ./config.ru ./config.ru
COPY --chown=app:app ./Rakefile ./Rakefile
COPY --chown=app:app ./Rakefile ./Rakefile
COPY --chown=app:app ./Procfile ./Procfile
COPY --chown=app:app ./babel.config.js ./babel.config.js
COPY --chown=app:app ./webpack.config.js ./webpack.config.js
COPY --chown=app:app ./.browserslistrc ./.browserslistrc
 
COPY --chown=app:app ./config/application.yml.default.docker $RAILS_ROOT/config/application.yml
COPY --chown=app:app ./config/newrelic.yml.docker $RAILS_ROOT/config/newrelic.yml
COPY --chown=app:app ./config/database.yml.docker $RAILS_ROOT/config/database.yml
 

RUN bundle config unset deployment
RUN bundle config build.nokogiri --use-system-libraries
RUN bundle config set --local deployment 'true'
RUN bundle config set --local path $BUNDLE_PATH
RUN bundle config set --local without 'deploy development test'
RUN bundle install 
RUN bundle binstubs --all

COPY package.json $RAILS_ROOT/package.json
COPY yarn.lock $RAILS_ROOT/yarn.lock
RUN yarn install --cache-folder .cache/yarn


# Generate and place SSL certificates for puma
RUN mkdir -p $RAILS_ROOT/keys
RUN openssl req -x509 -sha256 -nodes -newkey rsa:2048 -days 1825 \
    -keyout $RAILS_ROOT/keys/localhost.key \
    -out $RAILS_ROOT/keys/localhost.crt \
    -subj "/C=US/ST=Fake/L=Fakerton/O=Dis/CN=localhost"

# Precompile assets
RUN bundle exec rake assets:precompile --trace
   
EXPOSE 3001

CMD ["bundle", "exec", "puma", "-b", "ssl://0.0.0.0:3001?key=/dashboard/keys/localhost.key&cert=/dashboard/keys/localhost.crt"]
