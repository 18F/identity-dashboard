# Controller for Users
class UsersController < ApplicationController
  before_action -> { authorize User, :manage_users? }, except: %i[none]
  before_action -> { authorize User }, only: [:none]
  after_action :verify_authorized
  after_action :verify_policy_scoped, except: [:none]
  after_action :log_change, only: %i[create update destroy]
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
    @team_membership = @user&.team_memberships&.first
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

    role = Role.find_by(name: user_params.delete(:team_membership)&.dig(:role_name))
    authorize_and_make_admin(@user) if role && role == Role::LOGINGOV_ADMIN
    user.transaction do
      user.update!(user_params)
      remove_admin(user) if user.logingov_admin? && role && role != Role::LOGINGOV_ADMIN
      user.team_memberships.each do |membership|
        membership.role = role
        membership.save!
        log_change(membership) if membership.role_name_previously_changed?
      end
    end
    redirect_to users_url
  end

  def destroy
    @user = policy_scope(User).find_by(id: params[:id])
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

  def authorize_and_make_admin(user)
    admin_membership = TeamMembership.find_or_build_logingov_admin(user)
    authorize admin_membership
    user.transaction do
      admin_membership.save!
      user.update!(admin: true) # TODO: delete legacy admin property
    end
  end

  def remove_admin(user)
    admin_membership = TeamMembership.find_or_build_logingov_admin(user)
    authorize admin_membership
    admin_membership.transaction do
      admin_membership.destroy!
      user.update!(admin: false) # TODO: delete legacy admin property
    end
  end

  def user_params
    @user_params ||= params.require(:user).permit(:email, :admin, team_membership: :role_name)
  end

  def populate_role_if_missing
    @team_membership ||= @user.team_memberships.build
    @team_membership.role = @user.primary_role
  end

  def log_change(team_membership = false)
    record = team_membership || @user
    return if action_name != 'destroy' && record.previous_changes.empty?

    log.record_save(action_name, record)
  end
end
