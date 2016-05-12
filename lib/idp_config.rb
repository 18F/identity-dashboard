module IdP
  class Config
    def initialize
     @@settings ||= build_settings.freeze
    end

    def settings
      @@settings
    end

    def build_settings
      idp_env_config = YAML.load_file("#{Rails.root}/config/idp.yml").fetch(Rails.env, {}).symbolize_keys

      {
        issuer:                        'identity-dashboard',
        idp_sso_target_url:            ENV.fetch('IDP_SSO_URL', idp_env_config[:sso_url]),
        idp_cert:                      ENV.fetch('IDP_CERT', idp_env_config[:cert]),
        name_identifier_format:        ENV.fetch('IDP_NAME_ID_FORMAT', idp_env_config[:name_id_format]),
        allowed_clock_drift:           5.minutes,
        authn_context:                 'http://idmanagement.gov/ns/assurance/loa/1',
        single_signon_service_binding: 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
        double_quote_xml_attribute_values: true,
        security: {
          authn_requests_signed: true,
          embed_sign: true,
          digest_method: 'http://www.w3.org/2001/04/xmlenc#sha256',
          signature_method: 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256',
        }
      }
    end

    def logout_url
      settings[:idp_sso_target_url].gsub(/auth$/, 'logout')
    end
  end
end
