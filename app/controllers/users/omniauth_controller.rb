module Users
  # Controller for Login.gov authentication via Omniauth
  class OmniauthController < ApplicationController
    include TeamHelper

    def callback
      omniauth_info = request.env['omniauth.auth']['info']
      @user = UserSession.new(omniauth_info).call

      if @user && (can_edit_teams?(@user) || can_create_teams?(@user))
        sign_in @user
        store_id_token
        redirect_to session[:requested_url]
      else
        redirect_to users_none_url
      end
    end

    def failure
      redirect_to safe_origin_or_root
    end

    def store_id_token
      session[:id_token] = request.env.dig('omniauth.auth', 'credentials', 'id_token')
    end

    private

    def safe_origin_or_root
      origin = params[:origin].presence
      return root_path unless origin

      uri = URI.parse(origin)
      uri.host == request.host ? origin : root_path
    rescue URI::InvalidURIError
      root_path
    end
  end
end
