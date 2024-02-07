class IdentityConfig
  class << self
    attr_reader :store
  end

  CONVERTERS = {
    # Allows loading a string configuration from a system environment variable
    # ex: To read DATABASE_HOST from system environment for the database_host key
    # database_host: ['env', 'DATABASE_HOST']
    # To use a string value directly, you can specify a string explicitly:
    # database_host: 'localhost'
    string: proc do |(key_or_env, env_var)|
      if key_or_env == 'env' && env_var.present?
        ENV.fetch(env_var)
      elsif key_or_env.is_a?(String) && env_var.nil?
        key_or_env
      else
        raise 'invalid system environment configuration value'
      end
    end,
    comma_separated_string_list: proc do |value|
      value.split(',')
    end,
    integer: proc do |value|
      Integer(value)
    end,
    json: proc do |value, options: {}|
      JSON.parse(value, symbolize_names: options[:symbolize_names])
    end,
    boolean: proc do |value|
      case value
      when 'true', true
        true
      when 'false', false
        false
      else
        raise 'invalid boolean value'
      end
    end,
  }

  def initialize(read_env)
    @read_env = read_env
    @written_env = {}
  end

  def add(key, type: :string, is_sensitive: false, options: {})
    value = @read_env[key]
    raise "#{key} is required but is not present" if value.nil?
    converted_value = CONVERTERS.fetch(type).call(value, options: options)
    raise "#{key} is required but is not present" if converted_value.nil?

    @written_env[key] = converted_value
    @written_env
  end

  attr_reader :written_env

  def self.build_store(config_map)
    config = IdentityConfig.new(config_map)
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
    config.add(:idp_sp_url, type: :string)
    config.add(:idp_url, type: :string)
    config.add(:logo_upload_enabled, type: :boolean)
    config.add(:mailer_domain, type: :string)
    config.add(:newrelic_license_key, type: :string)
    config.add(:post_logout_redirect_uri, type: :string)
    config.add(:rack_timeout_service_timeout_seconds, type: :integer)
    config.add(:saml_sp_issuer, type: :string)
    config.add(:saml_sp_private_key, type: :string)
    config.add(:saml_sp_private_key_password, type: :string)
    config.add(:secret_key_base, type: :string)
    config.add(:serve_static_files, type: :boolean)
    config.add(:service_providers_with_nil_pkce, type: :comma_separated_string_list)

    @store = RedactedStruct.new('IdentityConfig', *config.written_env.keys, keyword_init: true).
      new(**config.written_env)
  end
end
