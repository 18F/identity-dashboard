require 'capybara/rspec'
require 'capybara/poltergeist'
require 'rack_session_access/capybara'

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, js_errors: true)
end

Capybara.javascript_driver = :poltergeist
Capybara.asset_host = 'http://localhost:3000'
Capybara.default_max_wait_time = 5
