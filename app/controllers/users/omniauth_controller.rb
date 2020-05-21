module Users
  class OmniauthController < ApplicationController
    # rubocop:disable Metrics/MethodLength
    def callback
      omniauth_info = request.env['omniauth.auth']['info']
      email = omniauth_info['email']
      @user = User.find_by(email: email)
      allow_unregistered_government_user(email)

      if @user
        @user.update!(uuid: omniauth_info['uuid'])
        sign_in @user
        redirect_to root_path

      # Can't find an account, tell user to contact login.gov team
      else
        redirect_to users_none_url
      end
    end
    # rubocop:enable Metrics/MethodLength

    private

    def allow_unregistered_government_user(received_email)
      return if @user
      allowed_tlds = (Figaro.env.auto_account_creation_tlds || '')&.split(',')
      return if allowed_tlds.filter do |tld|
        /(#{Regexp.escape(tld)})\Z/.match?(received_email)
      end.empty?

      @user = User.create(email: received_email)
    end
  end
end
