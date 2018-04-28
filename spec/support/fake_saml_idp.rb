require 'sinatra/base'
require 'saml_idp/controller'
require 'saml_idp/logout_request_builder'

class FakeSamlIdp < Sinatra::Base
  include SamlIdp::Controller

  post '/api/service_provider' do
    authorize do
      content_type :json
      { status: 'thanks' }.to_json
    end
  end

  get '/saml/auth' do
    build_configs
    validate_saml_request
    encode_response(user)
  end

  get '/saml/logout' do
    build_configs
    if params[:SAMLRequest]
      validate_saml_request
      encode_response(user)
    else
      logout_request_builder.signed
    end
  end

  private

  def authorize
    if authorization_token == Figaro.env.dashboard_api_token
      yield
    else
      status 401
    end
  end

  def authorization_token
    env['HTTP_X_LOGIN_DASHBOARD_TOKEN']
  end

  def logout_request_builder
    session_index = SecureRandom.uuid
    SamlIdp::LogoutRequestBuilder.new(
      session_index,
      SamlIdp.config.base_saml_location,
      'foo/bar/logout',
      user.uuid,
      OpenSSL::Digest::SHA256,
    )
  end

  def build_configs
    sp_config_settings = Saml::Config::SETTINGS
    SamlIdp.configure do |config|
      idp_base_url = 'http://idp.example.com'

      # for convenience we use the same cert/key pair as the SP
      # but in real-life these would be different.
      # NOTE that x509_certificate is also in test env in config/saml.yml
      # so that the SP can correctly decode our response.
      config.x509_certificate = sp_config_settings.certificate
      config.secret_key = sp_config_settings.private_key

      config.base_saml_location = "#{idp_base_url}/saml"
      config.single_service_post_location = "#{idp_base_url}/saml/auth"
      config.single_logout_service_post_location = "#{idp_base_url}/saml/logout"

      config.name_id.formats = {
        persistent: ->(principal) { principal.uuid },
        email_address: ->(principal) { principal.email }
      }

      config.attributes = {
        uuid: {
          getter: :uuid,
          name_format: Saml::XML::Namespaces::Formats::NameId::PERSISTENT,
          name_id_format: Saml::XML::Namespaces::Formats::NameId::PERSISTENT
        },
        email: {
          getter: :email,
          name_format: Saml::XML::Namespaces::Formats::NameId::EMAIL_ADDRESS,
          name_id_format: Saml::XML::Namespaces::Formats::NameId::EMAIL_ADDRESS
        }
      }

      config.service_provider.finder = lambda do |_issuer_or_entity_id|
        sp_cert = OpenSSL::X509::Certificate.new(config.x509_certificate)
        {
          cert: sp_cert,
          fingerprint: OpenSSL::Digest::SHA1.hexdigest(sp_cert.to_der),
          private_key: config.secret_key,
          assertion_consumer_logout_service_url: 'http://www.example.com/users/auth/saml/logout'
        }
      end
    end
  end

  def user
    if saml_request && saml_request.name_id
      User.find_by_uuid(saml_request.name_id)
    else
      FactoryBot.build(:user, uuid: SecureRandom.uuid)
    end
  end
end
