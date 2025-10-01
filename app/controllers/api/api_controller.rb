module Api
  # Controller for API authentication with token
  class ApiController < ApplicationController
    prepend_before_action :skip_session_load
    before_action :authenticate_token

    private

    def authenticate_token
      return unless IdentityConfig.store.api_token_required_enabled

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
