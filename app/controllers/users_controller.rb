class UsersController < ApplicationController
  before_action -> { authorize User }

  def index
    @users = User.all
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

  def none
    # permit script from hubspot
    override_content_security_policy_directives(
      script_src: %w(*.hsforms.net *.hsforms.com 'self'),
      img_src: %w(*.hsforms.com *.hsforms.net 'self'),
      style_src: %w('self' 'unsafe-inline')
      )
  end

  private

  def user_params
    params.require(:user).permit(:email, :admin)
  end
end
