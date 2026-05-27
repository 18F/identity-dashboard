# This application config store contains variables that are at least one of
# * intentionally easy to change where we don't mind requiring a server restart
# * specific to the server environment and difficult to determine from within the Rails app
# * sensitive and require more protection than ordinary per-application settings
class IdentityConfig
  class << self
    attr_reader :store

    # Add config options to an array to use later; defining a method like this allows us to
    # document the attributes with YARD.
    # YARD refuses to read comments that are nested in a method body.
    # @param name [Symbol]
    # @param args [Hash]
    def config_add(name, **args)
      @config_entries ||= []
      @config_entries.push({ name: name, args: args })
    end

    # Add the attributes defined with `config_add` to `configuration`.
    # This should be called only once and after all the attributes are defined with `config_add`
    # @param configuration [Identity::Hostdata::ConfigBuilder]
    def apply(configuration)
      @config_entries.each do |config_entry|
        configuration.add(config_entry[:name], **config_entry[:args])
      end
    end
  end

  # @!group Core Configuration Attributes

  # @!macro [attach] config_add
  #   @!attribute $1
  #   @return [$2]

  config_add :admin_email, type: :string
  # This ID should match what Airtable has as our app ID
  config_add :airtable_app_id, type: :string
  config_add :airtable_oauth_client_id, type: :string
  config_add :airtable_oauth_client_secret, type: :string
  config_add :airtable_table_id, type: :string
  config_add :asset_host, type: :string
  config_add :assets_version, type: :string
  config_add :auto_account_creation_tlds, type: :string
  config_add :aws_region, type: :string
  config_add :aws_logo_bucket, type: :string
  config_add :aws_reports_bucket, type: :string, allow_nil: true

  # Folders for reports in S3. This has to agree with folder structure used by the data team and
  # permissions set by the platform team in the relevant S3 bucket.
  config_add :aws_reports_path, type: :string, allow_nil: true
  config_add :db_pool, type: :integer
  config_add :devise_timeout_minutes, type: :integer
  config_add :dp_reaping_frequency, type: :integer
  config_add :certificate_expiration_warning_period, type: :integer
  # The token the portal uses outside of the `prod` environment to connect to the IdP API
  # to send ServiceProvider config updates
  config_add :dashboard_api_token, type: :string
  config_add :event_log_filename, type: :string
  # The IdP URL for sending ServiceProvider config updates, a feature currently
  # disabled in production
  config_add :idp_sp_url, type: :string
  # Used in several places as the root IdP URL, including knowing where to
  # hand off authentication for the portal itself
  config_add :idp_url, type: :string
  # Allows use of local disk instead of an S3 bucket for reports. Useful for testing the reports
  # feature without requiring a new S3 bucket. In production, it should not be set.
  config_add :local_reports_folder, type: :string, allow_nil: true
  # Unused — the portal currently generates no emails
  config_add :mailer_domain, type: :string
  config_add :newrelic_license_key, type: :string
  config_add :prod_like_env, type: :boolean
  # Where you're sent after logging out of the portal — configured here because it includes the
  # external-facing hostname.
  config_add :post_logout_redirect_uri, type: :string
  config_add :rack_timeout_service_timeout_seconds, type: :integer
  config_add :redis_pool_size, type: :integer
  config_add :redis_url, type: :string

  # The issuer string the portal itself will send when using IdP for auth —
  # despite being this option named `saml`, we now use OIDC.
  config_add :saml_sp_issuer, type: :string
  config_add :saml_sp_private_key, type: :string
  config_add :saml_sp_private_key_password, type: :string
  config_add :secret_key_base, type: :string
  config_add :serve_static_files, type: :boolean

  # This sets how many users are shown at once in the User index page,
  # which is currently internal-only.
  config_add :users_per_page, type: :integer
  # @!endgroup

  # @!group Feature Flags

  # These options expected to be higher churn than the previous group

  # When this flag is on, the scripts in identity-idp-config will need to use
  # token authentication to pull saved configurations via API.
  config_add :api_token_required_enabled, type: :boolean
  # When this flag is off, editing an existing ServiceProvider config uses the long form
  # instead of the wizard
  config_add :edit_button_uses_service_config_wizard, type: :boolean, allow_nil: true

  # @!endgroup

  def self.build_store(app_root:, rails_env:)
    Identity::Hostdata.load_config!(app_root:, rails_env:) do |config|
      apply(config)
    end
    @store = Identity::Hostdata.config
  end
end
