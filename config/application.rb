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
require "identity/logging/railtie"

require_relative '../lib/identity_config'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module IdentityDashboard
  class Application < Rails::Application
    configuration = Identity::Hostdata::ConfigReader.new(app_root: Rails.root).read_configuration(
      Rails.env, write_copy_to: Rails.root.join('tmp', 'application.yml')
    )
    IdentityConfig.build_store(configuration)

    # Initialize configuration defaults for originally generated Rails version.
    # TODO: once the Rails 7.0 upgrade is deployed, then come back to set 7.0 cache serialization
    # https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#new-activesupport-cache-serialization-format
    config.load_defaults 7.1
    config.active_support.cache_format_version = 7.1
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

    config.agencies = YAML.load_file 'config/agencies.yml'
  end
end
