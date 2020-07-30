module Users
  class SessionsController < Devise::SessionsController
    include ::ActionView::Helpers::DateHelper

    prepend_before_action :skip_timeout, only: [:active]

    def skip_timeout
      request.env['devise.skip_trackable'] = true
    end

    def active
      response.headers['Etag'] = '' # clear etags to prevent caching
      render json: { live: current_user.present?, timeout: session[:session_expires_at] }
    end

    def timeout
      flash[:notice] = I18n.t(
        'session_timedout',
        session_timeout: distance_of_time_in_words(Devise.timeout_in)
      )
      redirect_to root_url
    end

    def destroy
      if session[:id_token] && post_logout_redirect_uri
        sign_out(current_user)
        logout_request = self.class.logout_utility.build_request(
          id_token: session[:id_token],
          post_logout_redirect_uri: post_logout_redirect_uri
        )
        redirect_to(logout_request.redirect_uri)
      else
        super
      end
    end

    def post_logout_redirect_uri
      Figaro.env.post_logout_redirect_uri
    end

    def self.logout_utility
      @logout_utility ||=
        OmniAuth::LoginDotGov::LogoutUtility.new(idp_base_url: Rails.configuration.oidc['idp_url'])
    end
  end
end
