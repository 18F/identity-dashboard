class AuthTokensController < AuthenticatedController
  before_action :set_auth_token

  # GET /auth_tokens
  def index
  end

  # # GET /auth_tokens/1
  # def show
  # end

  # GET /auth_tokens/new
  def new
  end

  # # GET /auth_tokens/1/edit
  # def edit
  # end

  # POST /auth_tokens
  def create
    @auth_token = AuthToken.new_for_user(current_user)

    if @auth_token.save
      render json: {
        notice: 'Auth token was successfully created. Save this token in your password manager',
        token: @auth_token.ephemeral_token,
      }
    else
      render :new, status: :unprocessable_entity
    end
  end

  # # PATCH/PUT /auth_tokens/1
  # def update
  #   if @auth_token.update(auth_token_params)
  #     redirect_to @auth_token, notice: "Auth token was successfully updated.", status: :see_other
  #   else
  #     render :edit, status: :unprocessable_entity
  #   end
  # end

  # # DELETE /auth_tokens/1
  # def destroy
  #   @auth_token.destroy!
  #   redirect_to auth_tokens_url, notice: "Auth token was successfully destroyed.", status: :see_other
  # end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_auth_token
    @auth_token = current_user.auth_token
  end
end
