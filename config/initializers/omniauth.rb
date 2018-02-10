require 'oidc_config'

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :OpenIDConnect, OIDC::Config::SETTINGS
end
