class UsersController < ApplicationController
  before_action -> { authorize User }

  def index; end

  def edit
    @user = User.find_by(uuid: params[:id])
  end

  def update
    user = User.find_by(uuid: params[:id])
    user.update!(user_params)
    redirect_to users_url
  end

  private

  def user_params
    params.require(:user).permit(:admin)
  end
end
