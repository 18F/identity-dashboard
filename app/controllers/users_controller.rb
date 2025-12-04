# Controller for admin-only Users pages
class UsersController < ApplicationController
  include ModelChanges

  before_action -> { authorize User, :manage_users? }, except: %i[index none]
  before_action -> { authorize User, :view_users? }, only: [:index]
  before_action -> { authorize User }, only: [:none]
  after_action :verify_authorized
  after_action :verify_policy_scoped, except: [:none]
  after_action :log_user_changes, only: %i[create destroy]
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
    authorize_and_make_admin(@user) if role == Role::LOGINGOV_ADMIN
    authorize_and_make_login_readonly(@user) if role == Role::LOGINGOV_READONLY
    user.transaction do
      remove_admin(user) if login_admin_assigned_new_role? role
      remove_login_readonly(user) if login_readonly_assigned_new_role? role
      user.team_memberships.each do |membership|
        membership.role = role
        membership.save!
        log_membership_changes(membership) if membership.role_name_previously_changed?
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
      Role.active_roles_names.slice(
        'logingov_admin',
        'logingov_readonly',
        'partner_admin',
      ).invert
    else
      Role.active_friendly_names
    end
  end

  private

  def login_admin_assigned_new_role?(role)
    user.logingov_admin? && role && role != Role::LOGINGOV_ADMIN
  end

  def login_readonly_assigned_new_role?(role)
    user.logingov_readonly? && role && role != Role::LOGINGOV_READONLY
  end

  def authorize_and_make_admin(user)
    admin_membership = TeamMembership.find_or_build_logingov_admin(user)
    authorize admin_membership
    remove_login_readonly user if user.logingov_readonly?

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

  def authorize_and_make_login_readonly(user)
    readonly_membership = TeamMembership.find_or_build_logingov_readonly(user)
    authorize readonly_membership
    remove_admin user if user.logingov_admin?

    readonly_membership.save!
  end

  def remove_login_readonly(user)
    readonly_membership = TeamMembership.find_or_build_logingov_readonly(user)
    authorize readonly_membership
    readonly_membership.destroy!
  end

  def user_params
    @user_params ||= params.require(:user).permit(:email, :admin, team_membership: :role_name)
  end

  def populate_role_if_missing
    @team_membership ||= @user.team_memberships.build
    @team_membership.role = @user.primary_role
  end

  def log_user_changes
    if action_name == 'create'
      log.user_created(changes: changes_to_log(@user))
    elsif action_name == 'destroy'
      log.user_destroyed(changes: changes_to_log(@user))
    end
  end

  def log_membership_changes(membership)
    log.team_membership_updated(
      changes: changes_to_log(membership).merge(
        'team_user' => membership.user.email,
        'team' => membership.team.name,
      ),
    )
  end
end
