module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    skip_before_action :verify_authenticity_token

    def login
      "http://localhost:3000/openid_connect/authorize?acr_values=http%3A%2F%2Fidmanagement.gov%2Fns%2Fassurance%2Floa%2F1&client_id=urn%3Agov%3Agsa%3Aopenidconnect%3Asp%3Adashboard&nonce=abcdefghijklmnopabcdefghijklmnop&prompt=select_account&redirect_uri=http%3A%2F%2Flocalhost%3A3001&response_type=code&scope=openid+email&state=abcdefghijklmnopabcdefghijklmnop"
    end

    def result
      Rails.logger.debug "params: #{params}"
      token_response = token(params[:code])
    end

    def oidc
      @user = User.from_omniauth(auth_hash)
      return unless @user.persisted?
      sign_in @user
      redirect_to root_path
    end

    def failure
      if params[:SAMLResponse]
        saml_resp = params[:SAMLResponse]
        saml_resp_decoded = Base64.decode64(saml_resp)
        Rails.logger.warn("SAML: #{saml_resp}")
        Rails.logger.warn("SAML: #{saml_resp_decoded}")
      end
      flash[:alert] = env['omniauth.error'].to_s
    end

    def logout
      if params[:SAMLRequest]
        idp_logout_request
      elsif params[:SAMLResponse]
        validate_slo_response
      else
        flash[:alert] = 'SAMLRequest missing'
        render :failure
      end
    end

    private

    def saml_settings
      @_saml_settings ||= OneLogin::RubySaml::Settings.new(Saml::Config::SETTINGS.dup)
    end

    def auth_hash
      request.env['omniauth.auth']
    end

    def validate_slo_response
      slo_response = OneLogin::RubySaml::Logoutresponse.new(params[:SAMLResponse], saml_settings)
      if slo_response.validate
        flash[:notice] = t('omniauth.logout_ok')
        redirect_to root_url
      else
        flash[:alert] = t('omniauth.logout_fail')
        render :failure
      end
    end

    def idp_logout_request
      logout_request = OneLogin::RubySaml::SloLogoutrequest.new(
        params[:SAMLRequest],
        settings: saml_settings,
      )
      if logout_request.is_valid?
        redirect_to_idp_logout(logout_request)
      else
        invalid_logout_request(logout_request)
      end
    end

    def redirect_to_idp_logout(logout_request)
      Rails.logger.info "IdP initiated Logout for #{logout_request.nameid}"

      # delete our local Devise session
      sign_out

      logout_response = OneLogin::RubySaml::SloLogoutresponse.new.create(
        saml_settings,
        logout_request.id,
        nil,
        RelayState: params[:RelayState],
      )
      redirect_to logout_response
    end

    def invalid_logout_request(logout_request)
      error_msg = "IdP initiated LogoutRequest was not valid: #{logout_request.errors}"
      Rails.logger.error error_msg
      render inline: error_msg, status: 400
    end

    def client_assertion_jwt
      jwt_payload = {
        iss: CLIENT_ID,
        sub: CLIENT_ID,
        aud: http://localhost:3000/api/openid_connect/token,
        jti: SecureRandom.hex,
        nonce: SecureRandom.hex,
        exp: Time.now.to_i + 1000,
      }
      JWT.encode(jwt_payload, sp_private_key, 'RS256')
    end

    def token(code)
      json HTTParty.post(
        'http://localhost:3000/api/openid_connect/token',
        body: {
          grant_type: 'authorization_code',
          code: code,
          client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
          client_assertion: client_assertion_jwt,
        }
      ).body
    end

    def logout_uri(id_token)
      openid_configuration[:end_session_endpoint] + '?' + {
        id_token_hint: id_token,
        post_logout_redirect_uri: REDIRECT_URI,
        state: SecureRandom.hex,
      }.to_query
    end

    def json(response)
      JSON.parse(response.to_s).with_indifferent_access
    end

    def idp_public_key
      certs_response = json(
        HTTParty.get(openid_configuration[:jwks_uri]).body
      )
      JSON::JWK.new(certs_response[:keys].first).to_key
    end

    def private_key
      @private_key ||= OpenSSL::PKey::RSA.new(File.read('config/dashboard.key'))
    end

  end
end
