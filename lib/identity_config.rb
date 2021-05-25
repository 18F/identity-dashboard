class IdentityConfig
  class << self
    attr_reader :store
  end

  CONVERTERS = {
    string: proc { |value| value.to_s },
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
    config.add(:email_recipients, type: :string)
    config.add(:idp_sp_url, type: :string)
    config.add(:idp_url, type: :string)
    config.add(:logo_upload_enabled, type: :boolean)
    config.add(:mailer_domain, type: :string)
    config.add(:newrelic_license_key, type: :string)
    config.add(:post_logout_redirect_uri, type: :string)
    config.add(:risc_notifications_eventbridge_enabled, type: :boolean)
    config.add(:rack_timeout_service_timeout_seconds, type: :integer)
    config.add(:saml_sp_issuer, type: :string)
    config.add(:saml_sp_private_key, type: :string)
    config.add(:saml_sp_private_key_password, type: :string)
    config.add(:secret_key_base, type: :string)
    config.add(:serve_static_files, type: :boolean)
    config.add(:smtp_address, type: :string)
    config.add(:smtp_domain, type: :string)
    config.add(:smtp_host, type: :string)
    config.add(:smtp_password, type: :string)
    config.add(:smtp_port, type: :string)
    config.add(:smtp_username, type: :string)
    final_env = config.add(:smtp_username, type: :string)

    @store = RedactedStruct.new('IdentityConfig', *final_env.keys, keyword_init: true).
      new(**final_env)
  end
end
