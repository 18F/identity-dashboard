Rails.application.config.middleware.use OmniAuth::Builder do
  provider :login_dot_gov,
           client_id: Rails.configuration.oidc['client_id'],
           idp_base_url: Rails.configuration.oidc['idp_url'],
           private_key: OpenSSL::PKey::RSA.new(
             Figaro.env.saml_sp_private_key,
             Figaro.env.saml_sp_private_key_password
           ),
           redirect_uri: URI.join(
             Rails.configuration.oidc['dashboard_url'],
             '/auth/logindotgov/callback'
           )
end
