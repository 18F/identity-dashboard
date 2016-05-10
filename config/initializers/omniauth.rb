Rails.application.config.middleware.use OmniAuth::Builder do
  provider :saml,
    assertion_consumer_service_url:    ENV.fetch('CONSUMER_SERVICE_URL', 'http://localhost:3001/consume'),
    issuer:                            'identity-dashboard',
    idp_sso_target_url:                ENV.fetch('IDP_SSO_URL', 'http://localhost:3001/users/auth/saml'),
    #idp_sso_target_url_runtime_params: {:original_request_param => :mapped_idp_param},
    idp_cert:                          ENV.fetch('IDP_CERT'),
    idp_cert_fingerprint:              ENV.fetch('IDP_CERT_FINGERPRINT'),
    idp_cert_fingerprint_validator:    lambda { |fingerprint| fingerprint },
    name_identifier_format:            'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'
end
