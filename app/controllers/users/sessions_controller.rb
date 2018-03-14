module Users
  class SessionsController < Devise::SessionsController
    include ::ActionView::Helpers::DateHelper

    prepend_before_action :skip_timeout, only: [:active]

    def skip_timeout
      request.env['devise.skip_trackable'] = true
    end

    def new
      flash.clear
      redirect_to "" +
        Rails.configuration.oidc['idp_url'] + "/openid_connect/authorize?" +
        "&acr_values=http%3A%2F%2Fidmanagement.gov%2Fns%2Fassurance%2Floa%2F1" +
        "&client_id=" + CGI.escape(Rails.configuration.oidc['client_id']) +
        "&nonce=#{SecureRandom.hex}" +
        "&prompt=select_account" +
        "&redirect_uri=" + CGI.escape(Rails.configuration.oidc['dashboard_url'] + '/users/result') +
        "&response_type=code" +
        "&scope=openid+email" +
        "&state=#{SecureRandom.hex}"
    end

    def result
      unless params[:code] then redirect_to root_path end

      token_response = token(params[:code])

      id_token = JWT.decode(
        token_response[:id_token],
        idp_public_key,
        true,
        algorithm: 'RS256',
        leeway: 5
      ).first.with_indifferent_access

      puts "id_token[:sub]: #{id_token[:sub]}"
      puts "id_token[:email]: #{id_token[:email]}"

      # See if admin has created user an account
      @user = User.find_by_email(id_token[:email])
      if @user
        unless @user.uuid
          @user.uuid = id_token[:sub]
          @user.save
        end
        sign_in @user
        redirect_to service_providers_path

      # Can't find an account, tell user to contact login.gov team
      else
        redirect_to users_none_path
      end
    end

    def token(code)
      parse_json(
        HTTParty.post(
          Rails.configuration.oidc['idp_url'] + '/api/openid_connect/token',
          body: {
            grant_type: 'authorization_code',
            code: code,
            client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
            client_assertion: client_assertion_jwt,
          }
        ).body
      )
    end

    def client_assertion_jwt
      JWT.encode(
        {
          iss: Rails.configuration.oidc['client_id'],
          sub: Rails.configuration.oidc['client_id'],
          aud: Rails.configuration.oidc['idp_url'] + '/api/openid_connect/token',
          jti: SecureRandom.hex,
          nonce: SecureRandom.hex,
          exp: Time.now.to_i + 1000
        },
        OpenSSL::PKey::RSA.new(
          Figaro.env.saml_sp_private_key,
          Figaro.env.saml_sp_private_key_password
        ),
        'RS256'
      )
    end

    def idp_public_key
      certs_response = parse_json(HTTParty.get(Rails.configuration.oidc['idp_url'] + '/api/openid_connect/certs').body)
      JSON::JWK.new(certs_response[:keys].first).to_key
    end

    def parse_json(response)
      JSON.parse(response.to_s).with_indifferent_access
    end

    def active
      response.headers['Etag'] = '' # clear etags to prevent caching
      render json: { live: current_user.present?, timeout: session[:session_expires_at] }
    end

    def timeout
      flash[:notice] = I18n.t(
        'session_timedout',
        session_timeout: distance_of_time_in_words(Devise.timeout_in),
      )
      redirect_to root_url
    end

    def destroy
      # TODO: log out of IdP using OIDC logout endpoint
      #   https://developers.login.gov/oidc/#logout
      super
    end
  end
end
