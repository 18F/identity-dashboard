class UsersController < ApplicationController
  before_action -> { authorize User, :manage_users? }, except: %i[none]
  before_action -> { authorize User }, only: [:none]
  after_action :verify_authorized
  after_action :verify_policy_scoped
  helper_method :options_for_roles
  attr_reader :user

  def index
    @users = policy_scope(User).sorted
  end

  def new
    @user = policy_scope(User).new
  end

  def edit
    @user = policy_scope(User).find_by(id: params[:id])
    @user_team = @user && @user.user_teams.first
    populate_role_if_missing
    @has_no_teams = true if @user.teams.none?
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

    role = Role.find_by(name: user_params.delete(:user_team)&.dig(:role_name))
    user_params[:admin] = role.legacy_admin? if role
    user.transaction do
      user.update!(user_params)
      user.user_teams.each do |team|
        team.role = role
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

  def options_for_roles
    if @has_no_teams
      Role::ACTIVE_ROLES_NAMES.slice(:logingov_admin, :partner_admin).invert
    else
      Role::ACTIVE_ROLES_NAMES.invert
    end
  end

  private

  def user_params
    @user_params ||= params.require(:user).permit(:email, :admin, user_team: :role_name)
  end

  def populate_role_if_missing
    @user_team ||= @user.user_teams.build
    @user_team.role = @user.primary_role
  end
end
