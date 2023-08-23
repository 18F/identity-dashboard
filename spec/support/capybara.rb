require 'capybara/rspec'

require 'rack_session_access/capybara'

Capybara.register_driver :headless_chrome do |app|
  browser_options = Selenium::WebDriver::Chrome::Options.new
  browser_options.args << '--headless'
  browser_options.args << '--disable-gpu'
  browser_options.args << '--no-sandbox'

  Capybara::Selenium::Driver.new app,
                                 browser: :chrome,
                                 options: browser_options
end

Capybara.javascript_driver = :headless_chrome
Capybara.asset_host = 'http://localhost:3001'
Capybara.default_max_wait_time = 5

Capybara.server = :puma, { Silent: true }
