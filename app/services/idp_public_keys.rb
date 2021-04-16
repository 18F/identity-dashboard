# Ideally this could share an implementation with OmniAuth::LoginDotGov::IdpConfiguration
# However at this time, that class only exposes one public key
class IdpPublicKeys
  # @return [Array<OpenSSL::PKey::PKey>]
  def self.all
    Rails.cache.fetch('idp-public-keys', expires_in: 12.hours) do
      new.load_all
    end.map(&:to_key) # PKeys don't serialize, so we cache the JWKs
  end

  attr_reader :idp_url

  def initialize(idp_url: Rails.configuration.oidc['idp_url'])
    @idp_url = idp_url
  end

  # @return [Array<JSON::JWK>]
  def load_all
    jwks_configuration[:keys].map do |key_data|
      JSON::JWK.new(key_data)
    end
  end

  def openid_configuration
    @openid_configuration ||= JSON.parse(
      Faraday.get(URI.join(idp_url, '.well-known/openid-configuration')).body,
      symbolize_names: true,
    )
  end

  def jwks_configuration
    @jwks_configuration ||= JSON.parse(
      Faraday.get(openid_configuration[:jwks_uri]).body,
      symbolize_names: true,
    )
  end
end
