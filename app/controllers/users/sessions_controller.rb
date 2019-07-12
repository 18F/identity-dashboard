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
      # TODO: log out of IdP using OIDC logout endpoint
      #   https://developers.login.gov/oidc/#logout
      super
    end
  end
end
