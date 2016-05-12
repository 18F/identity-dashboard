require 'idp_config'

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :saml, IdP::Config.new.settings
end
