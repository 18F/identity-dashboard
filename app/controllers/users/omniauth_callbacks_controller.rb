module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    skip_before_action :verify_authenticity_token

    def saml
      @user = User.from_omniauth(auth_hash)
      if @user.persisted?
        sign_in @user
        redirect_to users_applications_path
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

    def after_omniauth_failure_path_for(scope)
      Rails.logger.warn("scope => #{scope}")
      super
    end

    private

    def auth_hash
      request.env['omniauth.auth']
    end
  end
end
