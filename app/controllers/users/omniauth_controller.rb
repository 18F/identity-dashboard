module Users
  class OmniauthController < ApplicationController
    def callback
      omniauth_info = request.env['omniauth.auth']['info']
      @user = Omniauth.new(omniauth_info).call

      if @user
        sign_in @user
        redirect_to session[:requsted_url]
      else
        redirect_to users_none_url
      end
    end
  end
end
