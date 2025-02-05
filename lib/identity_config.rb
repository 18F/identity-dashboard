class IdentityConfig
  class << self
    attr_reader :store
  end

  def self.build_store(app_root:, rails_env:)
    # rubocop:disable Metrics/BlockLength
    Identity::Hostdata.load_config!(app_root:, rails_env:) do |config|
      config.add(:admin_email, type: :string)
      config.add(:asset_host, type: :string)
      config.add(:assets_version, type: :string)
      config.add(:auto_account_creation_tlds, type: :string)
      config.add(:aws_region, type: :string)
      config.add(:aws_logo_bucket, type: :string)
      config.add(:db_pool, type: :integer)
      config.add(:dp_reaping_frequency, type: :integer)
      config.add(:certificate_expiration_warning_period, type: :integer)
      config.add(:dashboard_api_token, type: :string)
      config.add(:event_log_filename, type: :string)
      config.add(:idp_sp_url, type: :string)
      config.add(:idp_url, type: :string)
      config.add(:mailer_domain, type: :string)
      config.add(:newrelic_license_key, type: :string)
      config.add(:prod_like_env, type: :boolean)
      config.add(:post_logout_redirect_uri, type: :string)
      config.add(:rack_timeout_service_timeout_seconds, type: :integer)
      config.add(:saml_sp_issuer, type: :string)
      config.add(:saml_sp_private_key, type: :string)
      config.add(:saml_sp_private_key_password, type: :string)
      config.add(:secret_key_base, type: :string)
      config.add(:serve_static_files, type: :boolean)

      # Feature Flags, options expected to be higher churn than the above settings
      config.add(:access_controls_enabled, type: :boolean, allow_nil: true)
      config.add(:edit_button_uses_service_config_wizard, type: :boolean, allow_nil: true)
      config.add(:help_text_options_feature_enabled, type: :boolean)
      config.add(:service_config_wizard_enabled, type: :boolean, allow_nil: true)
    end
    @store = Identity::Hostdata.config
  end
end
