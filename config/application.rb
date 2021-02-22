require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
# require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module IdentityDashboard
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.0
    config.assets.unknown_asset_fallback = true

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.app_name = 'Partner Dashboard'
    config.oidc = config_for(:oidc)
    config.quiet_assets = true
    config.generators do |generate|
      generate.helper false
      generate.javascript_engine false
      generate.request_specs false
      generate.routing_specs false
      generate.stylesheets false
      generate.test_framework :rspec
      generate.view_specs false
    end
    config.action_controller.action_on_unpermitted_parameters = :raise

    config.lograge.custom_options = lambda do |event|
      event.payload[:timestamp] = Time.zone.now.iso8601
      event.payload[:uuid] = SecureRandom.uuid
      event.payload[:pid] = Process.pid
      event.payload.except(:params, :headers, :request, :response)
    end

    # Set the number of seconds the timeout warning should occur before
    # login session is timed out.
    config.session_timeout_warning_seconds = 120
    # Set the number of seconds in which to delay the start of the
    # PeriodicalQuery() call. Make sure the sum of this value and
    # session_timeout_warning_seconds is a multiple of 60 seconds.
    config.session_check_delay             = 60
    # Set the frequency of the PeriodicalQuery() call in seconds.
    # Make sure the sum of this value and session_timeout_warning_seconds
    # is a multiple of 60 seconds.
    config.session_check_frequency         = 60

    config.agencies = YAML.load_file 'config/agencies.yml'
  end
end
