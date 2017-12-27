require 'hashie/mash'

module Saml
  class Config
    # rubocop:disable AbcSize, MethodLength
    def self.build_settings
      Hashie::Mash.new(
        issuer:                         Figaro.env.saml_sp_issuer,
        assertion_consumer_service_url: Figaro.env.saml_sp_acs_url,
        idp_sso_target_url:             Figaro.env.saml_idp_sso_url,
        idp_slo_target_url:             Figaro.env.saml_idp_slo_url,
        idp_cert_fingerprint:           Figaro.env.saml_idp_fingerprint,
        name_identifier_format:         Figaro.env.saml_name_id_format,
        certificate:                    Figaro.env.saml_sp_certificate,
        private_key: OpenSSL::PKey::RSA.new(
          Figaro.env.saml_sp_private_key,
          Figaro.env.saml_sp_private_key_password,
        ).to_s,
        allowed_clock_drift: 5.minutes,
        authn_context: 'http://idmanagement.gov/ns/assurance/loa/1',
        single_signon_service_binding: 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
        double_quote_xml_attribute_values: true,
        security: {
          authn_requests_signed: true,
          logout_requests_signed: true,
          logout_responses_signed: true,
          embed_sign: false,
          digest_method: 'http://www.w3.org/2001/04/xmlenc#sha256',
          signature_method: 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256'
        },
      )
    end
    # rubocop:enable AbcSize, MethodLength, CyclomaticComplexity, PerceivedComplexity

    SETTINGS = build_settings.freeze

    def logout_url
      settings[:idp_slo_target_url]
    end
  end
end
