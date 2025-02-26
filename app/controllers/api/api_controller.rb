module Api
  class ApiController < ApplicationController
    before_action :authenticate_token

    private

    def authenticate_token
      authenticate_or_request_with_http_token do |token, options|
        @user = User.find_by!(email: options[:email])
        return false unless @user.admin?

        @user.auth_token.valid_token? token
      end
    end
  end
end