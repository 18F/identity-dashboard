require 'capybara/rspec'
require 'capybara/poltergeist'
require 'rack_session_access/capybara'

Capybara.javascript_driver = :poltergeist
Capybara.asset_host = 'http://localhost:3000'
Capybara.default_max_wait_time = 5
