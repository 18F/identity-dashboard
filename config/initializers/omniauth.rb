require 'saml_config'

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :saml, Saml::Config.new.settings
end
