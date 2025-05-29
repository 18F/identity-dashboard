module Api
  class ApiController < ApplicationController
    before_action :authenticate_token

    private

    def authenticate_token
      # Allow the auth headers to be optional for now.
      # TODO: make this mandatory before ATO
      return unless request.headers['HTTP_AUTHORIZATION']

      authenticate_or_request_with_http_token do |token, options|
        @user = User.find_by!(email: options[:email])
        auth_token = @user.auth_token if @user

        # Always fail if the auth_token is missing
        should_fail = !auth_token
        # Still run the validation check even if it's supposed to fail.
        # This should act as a defense against timing attacks.
        auth_token ||= AuthToken.new
        auth_token.valid_token?(token) && !should_fail
      end
    end
  end
end
