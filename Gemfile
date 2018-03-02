source 'https://rubygems.org'

ruby '~> 2.3.5'

gem 'actionmailer-text'
gem 'active_model_serializers'
gem 'delayed_job_active_record'
gem 'devise'
gem 'dotenv-rails'
gem 'enum_help'
gem 'figaro'
gem 'httparty'
gem 'jquery-rails'
gem 'json-jwt'
gem 'jwt'
gem 'newrelic_rpm', '>= 3.9.8'
gem 'nokogiri', '>= 1.7.1'
gem 'pg'
gem 'pundit'
gem 'rack-canonical-host'
gem 'rails', '~> 4.2.0'
gem 'recipient_interceptor'
gem 'ruby_regex'
gem 'sass-rails', '~> 5.0'
gem 'secure_headers', '~> 3.0.0'
gem 'simple_form'
gem 'slim-rails'
gem 'uglifier'

group :deploy do
  gem 'capistrano' # , '~> 3.4'
  gem 'capistrano-passenger'
  gem 'capistrano-rails' # , '~> 1.1', require: false
end

group :development do
  gem 'bummr', require: false
  gem 'quiet_assets'
  gem 'rubocop'
  gem 'web-console'
end

group :development, :test do
  gem 'bullet'
  gem 'factory_girl_rails'
  gem 'i18n-tasks'
  gem 'pry'
  gem 'rspec-rails', '~> 3.4.0'
  gem 'saml_idp', git: 'https://github.com/18F/saml_idp.git', branch: 'master'
  gem 'slim_lint'
end

group :test do
  gem 'climate_control'
  gem 'codeclimate-test-reporter', require: nil
  gem 'database_cleaner'
  gem 'poltergeist'
  gem 'rack_session_access'
  gem 'shoulda-matchers'
  gem 'sinatra'
  gem 'timecop'
  gem 'webmock'
end

group :production do
  gem 'rack-timeout'
  gem 'rails_12factor'
end
