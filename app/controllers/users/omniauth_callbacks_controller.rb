module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    skip_before_action :verify_authenticity_token

    def saml
      @user = User.from_omniauth(auth_hash)
      if @user.persisted?
        sign_in @user
        redirect_to root_path
      end
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
        saml_req = params[:SAMLRequest]
        saml_req_decoded = Base64.decode64(saml_req)
        Rails.logger.info saml_req_decoded
        idp_logout_request
      else
        flash[:alert] = 'SAMLRequest missing'
        render :failure
      end
    end

    private

    def auth_hash
      request.env['omniauth.auth']
    end

    def idp_logout_request
      settings = Saml::Config.new.settings
      logout_request = OneLogin::RubySaml::SloLogoutrequest.new(params[:SAMLRequest], settings: settings)
      unless logout_request.is_valid?
        error_msg = "IdP initiated LogoutRequest was not valid: #{logout_request.errors}"
        Rails.logger.error error_msg
        render :inline => error_msg
      else
        Rails.logger.info "IdP initiated Logout for #{logout_request.nameid}"

        # delete our local Devise session
        sign_out

        logout_response = OneLogin::RubySaml::SloLogoutresponse.new.create(
          settings,
          logout_request.id,
          nil,
          RelayState: params[:RelayState]
        )
        redirect_to logout_response
      end
    end
  end
end
