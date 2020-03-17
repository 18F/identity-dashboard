module Users
  class OmniauthController < ApplicationController
    def callback
      omniauth_info = request.env['omniauth.auth']['info']
      @user = User.find_by(email: omniauth_info['email'])
      if @user
        @user.update!(uuid: omniauth_info['uuid'])
        sign_in @user
        redirect_to root_path

      # Can't find an account, tell user to contact login.gov team
      else
        redirect_to users_none_url
      end
    end
  end
end
