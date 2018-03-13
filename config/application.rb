require File.expand_path('../boot', __FILE__)
require 'rails'
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'sprockets/railtie'
Bundler.require(*Rails.groups)
module IdentityDashboard
  class Application < Rails::Application
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
    config.active_job.queue_adapter = :delayed_job

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
  end
end
