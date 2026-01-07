# Controller for admin-only Users pages
class UsersController < ApplicationController
  include ModelChanges

  before_action -> { authorize User, :manage_users? }, except: %i[index none]
  before_action -> { authorize User }, only: [:index, :none]
  after_action :verify_authorized
  after_action :verify_policy_scoped, except: [:none]
  attr_reader :user

  def index
    per_page = IdentityConfig.store.users_per_page
    @page = [params[:page].to_i, 1].max
    @query = params[:query].to_s.strip

    base_scope = policy_scope(User).includes(team_memberships: [:role, :team])

    if @query.present?
      search_term = "%#{User.sanitize_sql_like(@query)}%"
      base_scope = base_scope.where('email ILIKE ?', search_term)
    end

    base_scope = base_scope.sorted
    @total_count = base_scope.count
    @total_pages = (@total_count.to_f / per_page).ceil
    @page = [@page, @total_pages].min if @total_pages > 0
    @users = base_scope.limit(per_page).offset((@page - 1) * per_page)
  end

  def new
    @user = policy_scope(User).new
  end

  def create
    @user = policy_scope(User).new(user_params)

    log_user_changes
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
        log_membership_changes(membership) if membership.role_name_changed?
        membership.save!
      end
    end
    redirect_to users_url
  end

  def destroy
    @user = policy_scope(User).find_by(id: params[:id])
    log_user_changes
    return unless user.destroy

    flash[:success] = I18n.t('notices.user_deleted', email: user.email)
    redirect_to users_path
  end

  def none; end

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
    end
  end

  def remove_admin(user)
    admin_membership = TeamMembership.find_or_build_logingov_admin(user)
    authorize admin_membership
    admin_membership.transaction do
      admin_membership.destroy!
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
    @user_params ||= params.require(:user).permit(:email, team_membership: :role_name)
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
