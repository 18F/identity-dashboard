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

Capybara.register_driver(:accessibility_driver) do |app|
  user_agent_string = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) ' \
                      'AppleWebKit/537.36 (KHTML, like Gecko) ' \
                      'Chrome/58.0.3029.110 Safari/537.36'
  Capybara::RackTest::Driver.new(app, headers: { 'HTTP_USER_AGENT' => user_agent_string })
end

Capybara.javascript_driver = :headless_chrome
Capybara.asset_host = 'http://localhost:3001'
Capybara.default_max_wait_time = 5

Capybara.server = :puma, { Silent: true }

