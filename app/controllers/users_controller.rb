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
    @user_team = @user && @user.user_teams.first
    populate_role_if_missing
  end

  def update
    user = User.find_by(id: params[:id])
    role = Role.find_by(name: user_params.delete(:user_team)&.dig(:role_name))
    user_params[:admin] = role.legacy_admin? if role
    user.transaction do
      user.update!(user_params)
      user.user_teams.each do |team|
        team.role_name = role.name
        team.save!
      end
    end
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
    @user_params ||= params.require(:user).permit(:email, :admin, user_team: :role_name)
  end

  def populate_role_if_missing
    @user_team ||= @user.user_teams.build
    @user_team.role ||= @user.admin? ? Role::SITE_ADMIN : Role.find_by(name: 'Partner Admin')
  end
end
