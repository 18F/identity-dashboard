class UsersController < ApplicationController
  before_action -> { authorize User, :manage_users? }, except: [:none]
  before_action -> { authorize User }, only: [:none]

  def index
    @users = User.all.sorted
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      flash[:success] = 'Success'
      redirect_to users_path
    else
      render :new
    end
  end

  def edit
    @user = User.find_by(id: params[:id])
  end

  def update
    user = User.find_by(id: params[:id])
    user.update!(user_params)
    redirect_to users_url
  end

  def destroy
    user = User.find_by(id: params[:id])
    return unless user.destroy
    flash[:success] = I18n.t('notices.user_deleted', email: user.email)
    redirect_to users_path
  end

  def none; end

  private

  def user_params
    params.require(:user).permit(:email, :admin)
  end
end
