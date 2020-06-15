source 'https://rubygems.org'

ruby '~> 2.6.5'

gem 'actionmailer-text', '>= 0.1.1'
gem 'active_model_serializers', '>= 0.10.7'
gem 'acts_as_paranoid'
gem 'aws-sdk-s3', require: false
gem 'bundler'
gem 'colorize'
gem 'devise', '~> 4.7.1'
gem 'dotenv-rails', '~> 2.4'
gem 'enum_help'
gem 'figaro'
gem 'httparty'
gem 'identity-hostdata', git: 'https://github.com/18F/identity-hostdata.git', branch: 'master'
gem 'identity_validations', git: 'https://github.com/18f/identity-validations.git', branch: 'master'
gem 'jquery-rails', '>= 4.3.5'
gem 'json-jwt', '>= 1.9.4'
gem 'jwt'
gem 'newrelic_rpm', '>= 3.9.8'
gem 'nokogiri', '~> 1.10'
gem 'omniauth-rails_csrf_protection', '~> 0.1', '>= 0.1.2'
gem 'omniauth_login_dot_gov', git: 'https://github.com/18f/omniauth_login_dot_gov.git'
gem 'paper_trail', '~> 10.3'
gem 'pg'
gem 'pry-rails'
gem 'pundit', '>= 2.1.0'
gem 'rack-canonical-host'
gem 'rails', '~> 5.2.4', '>= 5.2.4.3'
gem 'recipient_interceptor'
gem 'responders', '~> 2.4'
gem 'rest-client', '~> 2.0'
gem 'ruby_regex'
gem 'sass-rails', '~> 5.0', '>= 5.0.7'
gem 'secure_headers', '~> 3.9'
gem 'simple_form', '~> 5.0'
gem 'slim-rails', '~> 3.1'
gem 'subprocess', require: false
gem 'sucker_punch', '~> 2.0'
gem 'uglifier'
gem 'webpacker', '~> 4.x'

group :deploy do
  gem 'capistrano' # , '~> 3.4'
  gem 'capistrano-npm'
  gem 'capistrano-passenger'
  gem 'capistrano-rails' # , '~> 1.1', require: false
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'bummr', require: false
  gem 'listen', '~> 3.2'
  gem 'rubocop', '=0.54'
  gem 'rubocop-rspec'
  gem 'web-console', '>= 3.3.0'
end

group :development, :test do
  gem 'bullet'
  gem 'factory_bot_rails', '~> 4.8'
  gem 'i18n-tasks'
  gem 'pry-byebug'
  gem 'puma'
  gem 'rspec-rails', '~> 3.7', '>= 3.7.2'
  gem 'saml_idp', git: 'https://github.com/18F/saml_idp.git', branch: 'master'
  gem 'slim_lint'
end

group :test do
  gem 'capybara-selenium'
  gem 'climate_control'
  gem 'codeclimate-test-reporter', require: nil
  gem 'database_cleaner'
  gem 'fakefs', require: 'fakefs/safe'
  gem 'rack_session_access'
  gem 'rails-controller-testing', '>= 1.0.2'
  gem 'shoulda-matchers'
  gem 'simplecov'
  gem 'sinatra', '>= 2.0.2'
  gem 'timecop'
  gem 'webdrivers', '~> 3.0'
  gem 'webmock'
  gem 'websocket-driver', '= 0.6.5'
end

group :production do
  gem 'rack-timeout'
  gem 'rails_serve_static_assets'
end

gem 'autoprefixer-rails', '~> 9.6'
