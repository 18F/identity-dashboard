require 'hashie/mash'

module Saml
  class Config
    def initialize
      @@settings ||= build_settings.freeze
    end

    def settings
      @@settings
    end

    # rubocop:disable AbcSize, MethodLength
    def build_settings
      config_file = "#{Rails.root}/config/saml.yml"
      saml_env_config = Hashie::Mash.new(YAML.load_file(config_file).fetch(Rails.env, {}))
      Hashie::Mash.new(
        issuer: ENV.fetch('SP_ISSUER', saml_env_config[:sp_issuer]),
        idp_sso_target_url: ENV.fetch('IDP_SSO_URL', saml_env_config[:sso_url]),
        idp_slo_target_url: ENV.fetch('IDP_SLO_URL', saml_env_config[:slo_url]),
        idp_cert_fingerprint: ENV.fetch('IDP_FINGERPRINT', saml_env_config[:idp_fingerprint]),
        name_identifier_format: ENV.fetch('IDP_NAME_ID_FORMAT', saml_env_config[:name_id_format]),
        certificate: ENV.fetch('SP_CERTIFICATE', saml_env_config[:sp_certificate]),
        private_key: OpenSSL::PKey::RSA.new(
          ENV.fetch('SP_PRIVATE_KEY', saml_env_config[:sp_private_key]),
          ENV.fetch('SP_PRIVATE_KEY_PASSWORD', saml_env_config[:sp_private_key_password])
        ).to_s,
        allowed_clock_drift: 5.minutes,
        authn_context: 'http://idmanagement.gov/ns/assurance/loa/1',
        single_signon_service_binding: 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
        double_quote_xml_attribute_values: true,
        security: {
          authn_requests_signed: true,
          embed_sign: false,
          digest_method: 'http://www.w3.org/2001/04/xmlenc#sha256',
          signature_method: 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256'
        }
      )
    end
    # rubocop:enable AbcSize, MethodLength

    def logout_url
      settings[:idp_slo_target_url] || settings[:idp_sso_target_url].gsub(/auth$/, 'logout')
    end
  end
end
