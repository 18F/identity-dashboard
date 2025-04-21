class AuthTokensController < AuthenticatedController
  before_action -> { authorize AuthToken }
  before_action :set_auth_token
  after_action :verify_authorized
  # Skipping `:verify_policy_scoped` because it seems like that controller check is not compatible
  # with the AuthToken class handling that responsiblity.

  # GET /auth_tokens
  def index; end

  # GET /auth_tokens/new
  def new; end

  # POST /auth_tokens
  def create
    @auth_token = AuthToken.new_for_user(current_user)
    AuthTokenAuditor.new.in_controller(self, @auth_token)

    if @auth_token.save
      render 'index'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_auth_token
    @auth_token = AuthToken.for(current_user) || AuthToken.new_for_user(current_user)
  end
end
