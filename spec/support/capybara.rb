require 'capybara/rspec'
require 'rack_session_access/capybara'

# Resolve the chromedriver binary. When one is provided explicitly via
# CHROMEDRIVER_PATH or is on PATH (e.g. from devenv/Nix or CI), point Selenium
# at it. Otherwise this returns nil and Selenium falls back to its bundled
# `selenium-manager` helper, which downloads a chromedriver matching the
# installed Chrome (the typical path on local macOS). Note: selenium-manager
# ships a macOS universal binary (x86_64 + arm64) but only an x86_64 build for
# Linux, so on aarch64-linux it cannot execute. Those environments must provide
# chromedriver on PATH or use devenv.
def chromedriver_service
  path = ENV['CHROMEDRIVER_PATH'].presence || `command -v chromedriver 2>/dev/null`.strip.presence
  return nil if path.nil?

  Selenium::WebDriver::Service.chrome(path: path)
end

Capybara.register_driver :headless_chrome do |app|
  browser_options = Selenium::WebDriver::Chrome::Options.new
  browser_options.args << '--headless'
  browser_options.args << '--disable-gpu'
  browser_options.args << '--no-sandbox'

  Capybara::Selenium::Driver.new app,
                                 browser: :chrome,
                                 options: browser_options,
                                 service: chromedriver_service
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
