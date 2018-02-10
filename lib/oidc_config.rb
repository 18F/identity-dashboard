module OIDC
  class Config
    # rubocop:disable AbcSize, MethodLength
    def self.build_settings
      {
        issuer:                 'urn:gov:gsa:openidconnect:sp:dashboard',
        idp_cert_fingerprint:   Figaro.env.idp_fingerprint,
        certificate:            Figaro.env.dashboard_certificate,
        # private_key: OpenSSL::PKey::RSA.new(
        #   Figaro.env.dashboard_private_key,
        #   Figaro.env.dashboard_private_key_password
        # ).to_s,
        allowed_clock_drift: 5.minutes,
        authn_context: 'http://idmanagement.gov/ns/assurance/loa/1'
      }
    end
    # rubocop:enable AbcSize, MethodLength, CyclomaticComplexity, PerceivedComplexity

    SETTINGS = build_settings.freeze
  end
end

#
# config.omniauth :openid_connect, {
#   name: :my_provider,
#   scope: [:openid, :email, :profile, :address],
#   response_type: :code,
#   client_options: {
#     port: 443,
#     scheme: "https",
#     host: "myprovider.com",
#     identifier: ENV["OP_CLIENT_ID"],
#     secret: ENV["OP_SECRET_KEY"],
#     redirect_uri: "http://myapp.com/users/auth/openid_connect/callback",
#   },
# }
