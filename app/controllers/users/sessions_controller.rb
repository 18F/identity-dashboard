module Users
  # Controller for user Sessions
  class SessionsController < Devise::SessionsController
    include ::ActionView::Helpers::DateHelper

    def destroy
      log_session_duration
      if Rails.configuration.oidc['client_id'] && post_logout_redirect_uri
        sign_out(current_user)
        logout_request = self.class.logout_utility.build_request(
          client_id: Rails.configuration.oidc['client_id'],
          post_logout_redirect_uri: post_logout_redirect_uri,
        )
        redirect_to(logout_request.redirect_uri, allow_other_host: true)
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

    private

    def log_session_duration
      return unless session[:session_started_at].present?

      session_started_at = session[:session_started_at]
      session_started_at = Time.zone.parse(session_started_at) if session_started_at.is_a?(String)

      log.session_duration(
        session_started_at: session_started_at,
        session_ended_at: Time.zone.now,
      )
    end
  end
end
