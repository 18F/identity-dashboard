module Users
  class SessionsController < Devise::SessionsController
    include ::ActionView::Helpers::DateHelper

    def destroy
      if session[:id_token] && post_logout_redirect_uri
        sign_out(current_user)
        logout_request = self.class.logout_utility.build_request(
          id_token: session[:id_token],
          post_logout_redirect_uri: post_logout_redirect_uri,
        )
        redirect_to(logout_request.redirect_uri)
      else
        super
      end
    end

    def post_logout_redirect_uri
      IdentityConfig.store.post_logout_redirect_uri
    end

    def self.logout_utility
      @logout_utility ||=
        OmniAuth::LoginDotGov::LogoutUtility.new(idp_base_url: Rails.configuration.oidc['idp_url'])
    end
  end
end
