class UsersController < ApplicationController
  before_action -> { authorize User, :manage_users? }, except: %i[edit update none]
  before_action -> { authorize User }, only: [:none]
  after_action :verify_authorized
  after_action :verify_policy_scoped

  attr_reader :user

  def index
    @users = policy_scope(User).sorted
  end

  def new
    @user = policy_scope(User).new
  end

  def edit
    @user = policy_scope(User).find_by(id: params[:id])
    authorize(@user || User)
    @user_team = @user && @user.user_teams.first
    populate_role_if_missing
  end

  def create
    @user = policy_scope(User).new(user_params)

    if @user.save
      flash[:success] = 'Success'
      redirect_to users_path
    else
      render :new
    end
  end

  def update
    @user = policy_scope(User).find_by(id: params[:id])
    authorize(user || User)

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
    user = policy_scope(User).find_by(id: params[:id])
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
    @user_team.role ||= @user.admin? ? Role::SITE_ADMIN : Role.find_by(name: 'partner_admin')
  end
end
