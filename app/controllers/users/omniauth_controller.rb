module Users
  class OmniauthController < ApplicationController
    def callback
      omniauth_info = request.env['omniauth.auth']['info']
      @user = UserSession.new(omniauth_info).call

      if @user
        sign_in @user
        set_id_token
        redirect_to session[:requested_url]
      else
        redirect_to users_none_url
      end
    end

    def set_id_token
      session[:id_token] = request.env.dig('omniauth.auth', 'credentials', 'id_token')
    end
  end
end
