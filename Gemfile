source 'https://rubygems.org'

ruby '~> 2.3.5'

gem 'actionmailer-text', '>= 0.1.1'
gem 'active_model_serializers', '>= 0.10.7'
gem 'devise', '>= 4.4.3'
gem 'dotenv-rails', '>= 2.4.0'
gem 'enum_help'
gem 'figaro'
gem 'httparty'
gem 'jquery-rails', '>= 4.3.3'
gem 'json-jwt', '>= 1.9.4'
gem 'jwt'
gem 'newrelic_rpm', '>= 3.9.8'
gem 'nokogiri', '>= 1.7.1'
gem 'pg'
gem 'pry-rails'
gem 'pundit'
gem 'rack-canonical-host', '>= 0.2.3'
gem 'rails', '~> 5.1.6'
gem 'recipient_interceptor'
gem 'rest-client', '~> 2.0'
gem 'ruby_regex'
gem 'sass-rails', '~> 5.0', '>= 5.0.7'
gem 'secure_headers', '~> 3.0'
gem 'simple_form', '>= 3.5.0'
gem 'slim-rails', '>= 3.1.3'
gem 'uglifier'

group :deploy do
  gem 'capistrano' # , '~> 3.4'
  gem 'capistrano-passenger'
  gem 'capistrano-rails' # , '~> 1.1', require: false
end

group :development do
  gem 'bummr', require: false
  gem 'rubocop'
  gem 'web-console', '>= 3.3.0'
end

group :development, :test do
  gem 'bullet'
  gem 'factory_bot_rails', '>= 4.8.2'
  gem 'i18n-tasks'
  gem 'pry-byebug'
  gem 'rspec-rails', '~> 3.7', '>= 3.7.2'
  gem 'saml_idp', git: 'https://github.com/18F/saml_idp.git', branch: 'master'
  gem 'slim_lint'
end

group :test do
  gem 'climate_control'
  gem 'codeclimate-test-reporter', require: nil
  gem 'database_cleaner'
  gem 'poltergeist', '>= 1.17.0'
  gem 'rack_session_access', '>= 0.2.0'
  gem 'rails-controller-testing', '>= 1.0.2'
  gem 'shoulda-matchers'
  gem 'sinatra', '>= 2.0.3'
  gem 'timecop'
  gem 'webmock'
  gem 'websocket-driver', '=0.6.5'
end

group :production do
  gem 'rack-timeout'
  gem 'rails_12factor'
end
