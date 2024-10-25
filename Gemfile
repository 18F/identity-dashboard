source 'https://rubygems.org'

ruby "~> #{File.read(File.join(__dir__, '.ruby-version')).strip}"

gem 'actionmailer-text', '>= 0.1.1'
gem 'active_model_serializers', '>= 0.10.14'
gem 'active_record_upsert'
gem 'acts_as_paranoid'
# pod identity requires 3.188.0
# https://docs.aws.amazon.com/eks/latest/userguide/pod-id-minimum-sdk.html
gem 'aws-sdk-core', '>= 3.188.0'
gem 'aws-sdk-s3', require: false
gem 'bundler'
gem 'colorize'
gem 'cssbundling-rails'
gem 'csv'
gem 'devise', '~> 4.9.3'
gem 'dotenv-rails', '~> 2.8', '>= 2.8.1'
gem 'enum_help'
gem 'faraday'
gem 'identity-hostdata', git: 'https://github.com/18F/identity-hostdata.git', tag: 'v4.1.0'
gem 'identity-logging', git: 'https://github.com/18f/identity-logging.git', tag: 'v0.1.0'
gem 'identity_validations', git: 'https://github.com/18f/identity-validations.git', tag: 'v0.8.0'
gem 'jsbundling-rails', '>= 1.2.2'
gem 'json-jwt', '>= 1.15.3'
gem 'jwt'
gem 'kaminari'
gem 'newrelic_rpm', '>= 6.14.0'
gem 'nokogiri', '~> 1.16.5'
gem 'omniauth_login_dot_gov', git: 'https://github.com/18f/omniauth_login_dot_gov.git',
                              branch: 'main'
gem 'omniauth-rails_csrf_protection'
gem 'paper_trail', '~> 15.0', '>= 15.0.0'
gem 'puma', '>= 6.4.2'
gem 'pg'
gem 'propshaft'
gem 'pry-rails'
gem 'pundit', '>= 2.3.1'
gem 'rack-canonical-host', '>= 1.2.0'
gem 'rack-timeout', require: false
# If you update the rails version, please change the targeted
# version in .rubocop.yml
gem 'rails', '~> 7.1.4', '>= 7.1.4.1'
gem 'redacted_struct'
gem 'responders', '~> 3.1', '>= 3.1.1'
gem 'rest-client', '~> 2.1'
gem 'rouge'
gem 'ruby_regex'
gem 'saml_idp', github: '18F/saml_idp', tag: '0.23.0-18f'
gem 'secure_headers', '~> 3.9'
gem 'simple_form', '~> 5.3', '>= 5.3.0'
gem 'uglifier'
gem 'wicked', '~> 2.0'

group :deploy do
  gem 'capistrano'
  gem 'capistrano-npm'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'bummr', require: false
  gem 'listen', '~> 3.3'
  gem 'web-console', '>= 4.2.1'
end

group :development, :test do
  gem 'bullet', '>= 7.0.5'
  gem 'factory_bot_rails', '~> 6.3', '>= 6.3.0'
  gem 'i18n-tasks', '>= 1.0.13'
  gem 'pry-byebug'
  gem 'rspec-rails', '~> 6.0', '>= 6.0.0'
  gem 'rubocop', '~> 1.62.0', require: false
  gem 'rubocop-rails', '>= 2.9', require: false
  gem 'rubocop-rspec', require: false
  gem 'rspec_junit_formatter'
end

group :test do
  gem 'axe-core-rspec', '~> 4.2'
  gem 'capybara', '>= 3.39.1'
  gem 'selenium-webdriver'
  gem 'codeclimate-test-reporter', require: nil
  gem 'database_cleaner', '>= 2.0.2'
  gem 'fakefs', require: 'fakefs/safe'
  gem 'rack_session_access'
  gem 'rails-controller-testing', '>= 1.0.5'
  gem 'shoulda-matchers'
  gem 'simplecov', '~> 0.22.0'
  gem 'simplecov-cobertura'
  gem 'sinatra', '>= 4.0.0'
  gem 'timecop'
  gem 'webmock'
  gem 'websocket-driver', '= 0.7.3'
end

group :production do
  gem 'rails_serve_static_assets'
end

gem 'autoprefixer-rails', '~> 10.1'
