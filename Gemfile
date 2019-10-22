source 'https://rubygems.org'

# ruby '~> 2.3.5'

gem 'actionmailer-text'
gem 'active_model_serializers'
gem 'colorize'
gem 'devise', '~> 4.7.1'
gem 'dotenv-rails'
gem 'enum_help'
gem 'figaro'
gem 'httparty'
gem 'identity_validations', git: 'https://github.com/18f/identity-validations.git', branch: 'master'
gem 'jquery-rails', '>= 4.3.4'
gem 'json-jwt', '>= 1.9.4'
gem 'jwt'
gem 'newrelic_rpm', '>= 3.9.8'
gem 'nokogiri', '~> 1.9'
gem 'omniauth-rails_csrf_protection', '~> 0.1'
gem 'omniauth_login_dot_gov', git: 'https://github.com/18f/omniauth_login_dot_gov.git'
gem 'pg'
gem 'pry-rails'
gem 'pundit'
gem 'rack-canonical-host'
gem 'rails', '~> 5.1.6'
gem 'recipient_interceptor'
gem 'rest-client', '~> 2.0'
gem 'ruby_regex'
gem 'sass-rails', '~> 5.0', '>= 5.0.7'
gem 'secure_headers', '~> 3.0'
gem 'simple_form', '~> 3.0'
gem 'slim-rails'
gem 'uglifier'

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
  gem 'rubocop', '=0.54'
  gem 'web-console'
end

group :development, :test do
  gem 'bullet'
  gem 'factory_bot_rails'
  gem 'i18n-tasks'
  gem 'pry-byebug'
  gem 'rspec-rails', '~> 3.4'
  gem 'saml_idp', git: 'https://github.com/18F/saml_idp.git', branch: 'master'
  gem 'slim_lint'
end

group :test do
  gem 'climate_control'
  gem 'codeclimate-test-reporter', require: nil
  gem 'database_cleaner'
  gem 'poltergeist'
  gem 'rack_session_access'
  gem 'rails-controller-testing'
  gem 'shoulda-matchers'
  gem 'simplecov'
  gem 'sinatra', '>= 2.0.2'
  gem 'timecop'
  gem 'webmock'
  gem 'websocket-driver', '=0.6.5'
end

group :production do
  gem 'rack-timeout'
  gem 'rails_12factor'
end

gem 'autoprefixer-rails', '~> 9.6'
