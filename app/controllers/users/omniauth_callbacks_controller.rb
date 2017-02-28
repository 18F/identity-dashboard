module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    skip_before_action :verify_authenticity_token

    def saml
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
      @_saml_settings ||= OneLogin::RubySaml::Settings.new(Saml::Config.new.settings.dup)
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
        settings: saml_settings
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
        RelayState: params[:RelayState]
      )
      redirect_to logout_response
    end

    def invalid_logout_request(logout_request)
      error_msg = "IdP initiated LogoutRequest was not valid: #{logout_request.errors}"
      Rails.logger.error error_msg
      render inline: error_msg, status: 400
    end
  end
end
