class Teams::UsersController < AuthenticatedController
  before_action :authorize_manage_team_users,
                unless: -> { IdentityConfig.store.access_controls_enabled }

  if IdentityConfig.store.access_controls_enabled
    after_action :verify_authorized
    after_action :verify_policy_scoped
    before_action :log_change, only: %i[destroy]
    after_action :log_change, only: %i[create update]
  end

  helper_method :roles_for_options, :show_actions?

  def index
    authorize current_team_membership if IdentityConfig.store.access_controls_enabled
    @team_memberships = team.team_memberships.where
      .associated(:user, :team)
      .includes(:user)
      .order('users.email')
  end

  def new
    authorize current_team_membership if IdentityConfig.store.access_controls_enabled
    @user = policy_scope(User).new
  end

  def edit
    unless IdentityConfig.store.access_controls_enabled
      redirect_to(action: :index, team_id: team)
      return
    end

    authorize team_membership
    @user = team_membership.user
  end

  def create
    if IdentityConfig.store.access_controls_enabled
      new_team_membership = policy_scope(TeamMembership).build(
        team: team,
        user: new_team_member,
      )
      new_team_membership.set_default_role
      authorize new_team_membership
      new_team_membership.save!
      flash[:success] = I18n.t('teams.users.create.success', email: member_email)
      redirect_to new_team_user_path and return
    end
    new_team_member.team_memberships << TeamMembership.create!(user_id: new_team_member.id,
                                                               group_id: team.id)
    flash[:success] = I18n.t('teams.users.create.success', email: member_email)
    redirect_to new_team_user_path and return
  rescue ActiveRecord::RecordInvalid => err
    skip_authorization
    flash[:error] = "'#{member_email}': " + err.record.errors.full_messages.join(', ')
    redirect_to new_team_user_path
  end

  def update
    unless IdentityConfig.store.access_controls_enabled
      redirect_to(action: :index, team_id: team)
      return
    end
    team_membership.assign_attributes(team_membership_params)
    authorize team_membership
    team_membership.save
    if team_membership.errors.any?
      @user = team_membership.user
      render :edit
    else
      redirect_to team_users_path(team)
    end
  end

  def remove_confirm
    if IdentityConfig.store.access_controls_enabled
      team_membership_to_delete = policy_scope(TeamMembership).find_by(user:, team:)
      authorize team_membership_to_delete
      return
    end

    if user_present_not_current_user(user)
      render :remove_confirm
    else
      render_401
    end
  end

  def destroy
    if IdentityConfig.store.access_controls_enabled
      # If unauthorized, the option to delete should not show up in the UI
      # so it is acceptable to return a 401 instead of a redirect here
      authorize policy_scope(TeamMembership).find_by(user:, team:)
      team.users.delete(user)
      flash[:success] = I18n.t('teams.users.remove.success', email: user.email)
      redirect_to team_users_path and return
    end
    if user_present_not_current_user(user)
      team.users.delete(user)
      flash[:success] = I18n.t('teams.users.remove.success', email: user.email)
      redirect_to team_users_path
    else
      render_401
    end
  end

  def roles_for_options
    policy(team_membership).roles_for_edit.map { |r| [r.friendly_name, r.name] }
  end

  def show_actions?
    return true unless IdentityConfig.store.access_controls_enabled

    @team_memberships.any? { |membership| policy(membership).destroy? || policy(membership).edit? }
  end

  private

  def member_email
    user_params.require(:email).downcase
  end

  def new_team_member
    @new_team_member ||= User.find_or_create_by!(email: member_email)
    @user = @new_team_member
  end

  def user
    @user ||= team.users.find_by(id: params[:id])
  end

  def user_present_not_current_user(user)
    user.present? && user != current_user
  end

  def user_params
    params.require(:user).permit(:email)
  end

  def team_membership_params
    params.require(:team_membership).permit(:role_name)
  end

  def team
    @team ||= policy_scope(Team).find_by(id: params[:team_id])
  end

  def current_team_membership
    if team
      @current_team_membership = policy_scope(team.team_memberships).find_by(user: current_user)
    end
    @current_team_membership ||= policy_scope(TeamMembership).new
  end

  def team_membership
    @team_membership ||= policy_scope(TeamMembership).find_by(user:, team:)
  end

  def authorize_manage_team_users
    authorize(
      current_team_membership,
      :manage_team_users?,
      policy_class: TeamMembershipPolicy,
    )
  end

  def log_change
    log.record_save(action_name, team_membership)
  end
end
