source 'https://rubygems.org'

ruby '2.3.0'

gem 'actionmailer-text'
gem 'autoprefixer-rails'
gem 'bourbon', '5.0.0.beta.5'
gem 'coffee-rails', '~> 4.1.0'
gem 'delayed_job_active_record'
gem 'devise'
gem 'dotenv-rails'
gem 'enum_help'
gem 'flutie'
gem 'hashie'
gem 'high_voltage'
gem 'honeybadger'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'kaminari-bootstrap', '~> 3.0.1'
gem 'neat', '~> 1.7.0'
gem 'newrelic_rpm', '>= 3.9.8'
gem 'nokogiri', '>= 1.6.8'
gem 'normalize-rails', '~> 3.0.0'
gem 'omniauth-saml'
gem 'pg'
gem 'puma'
gem 'pundit'
gem 'rack-canonical-host'
gem 'rails', '~> 4.2.0'
gem 'recipient_interceptor'
gem 'ruby_regex'
gem 'sass-rails', '~> 5.0'
gem 'secure_headers', '~> 3.0.0'
gem 'simple_form', git: 'https://github.com/amoose/simple_form.git', branch: 'feature/aria-invalid'
gem 'slim-rails'
gem 'uglifier'
gem 'us_web_design_standards', git: 'https://github.com/jessieay/us_web_design_standards_gem.git', branch: 'rails-assets-fixes'

group :development do
  gem 'quiet_assets'
  gem 'slim_lint'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'web-console'
end

group :development, :test do
  gem 'awesome_print'
  gem 'bullet'
  gem 'bundler-audit', '>= 0.5.0', require: false
  gem 'factory_girl_rails'
  gem 'mailcatcher', '0.6.3'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rspec-rails', '~> 3.4.0'
end

group :development, :staging do
  gem 'rack-mini-profiler', require: false
end

group :test do
  gem 'database_cleaner'
  gem 'formulaic'
  gem 'launchy'
  gem 'poltergeist'
  gem 'rack_session_access'
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
  gem 'timecop'
  gem 'webmock'
end

group :staging, :production do
  gem 'rack-timeout'
  gem 'rails_12factor'
end
