# Controls Team Users pages, where partners update the users for a given team
class Teams::UsersController < AuthenticatedController
  include ModelChanges

  before_action :authorize_manage_team_users,
                unless: -> { IdentityConfig.store.access_controls_enabled }

  if IdentityConfig.store.access_controls_enabled
    after_action :verify_authorized
    after_action :verify_policy_scoped
    after_action :log_change, only: %i[create update]
  end

  helper_method :roles_for_options, :show_actions?

  def index
    authorize current_team_membership if IdentityConfig.store.access_controls_enabled
    @team_memberships = team && team.team_memberships.where
      .associated(:user, :team)
      .includes(:user)
      .order('users.email')
    @team_memberships ||= []
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

    airtable_api = Airtable.find_by(user: current_user) ||
      Airtable.new(current_user)

    if airtable_api.has_token?
      @needs_to_confirm_partner_admin = true if params[:need_to_confirm_role]
    else
      @remove_partner_admin = true
      airtable_api.refresh_token if airtable_api.needs_refreshed_token?

      base_url = "#{request.protocol}#{request.host_with_port}"
      @oauth_url = airtable_api&.generate_oauth_url(base_url)
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
      redirect_to(action: :index, team_id: team) and return
    end

    team_membership.assign_attributes(team_membership_params)
    authorize team_membership

    if partner_admin_confirmation_needed?
      flash[:error] =
        "User #{team_membership.user.email} is not a Partner Admin in Airtable.
          Please verify with the appropriate Account Manager that this user should
          be given the Partner Admin role."

      redirect_to edit_team_user_path(team, team_membership.user,
                                      need_to_confirm_role: true) and return
    end
    team_membership.save
    if team_membership.errors.any?
      @user = team_membership.user
      render :edit
    end
    redirect_to team_users_path(team)
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
      log_change
      team.users.delete(user)
      flash[:success] = I18n.t('teams.users.remove.success', email: user.email)
      redirect_to team_users_path and return
    end
    if user_present_not_current_user(user)
      log_change
      team.users.delete(user)
      flash[:success] = I18n.t('teams.users.remove.success', email: user.email)
      redirect_to team_users_path
    else
      render_401
    end
  end

  def roles_for_options
    roles = policy(team_membership).roles_for_edit
    unless Airtable.find_by(user: current_user)&.has_token?
      roles = roles.reject { |role| role.name == 'partner_admin' }
    end
    roles.map { |r| [r.friendly_name, r.name] }
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
    @current_team_membership ||= policy_scope(TeamMembership).build(team:)
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
    # TODO: Log error if team_membership is not valid
    return unless team_membership.present?

    if action_name == 'create'
      log.team_membership_created(changes:)
    elsif action_name == 'update'
      # do not log if there are no changes
      return if team_membership.previous_changes.empty?

      log.team_membership_updated(changes:)
    else
      log.team_membership_destroyed(changes:)
    end
  end

  def changes
    changes_to_log(team_membership).merge(
      'team_user' => team_membership.user.email,
      'team' => team_membership.team.name,
    )
  end

  def verified_partner_admin?
    airtable_api = Airtable.find_by(user: current_user) ||
      Airtable.new(current_user)

    redirect_uri = airtable_api.build_redirect_uri(request)
    airtable_api.refresh_token(redirect_uri) if airtable_api.needs_refreshed_token?
    issuers = []
    ServiceProvider.where(team: self.team).each do |sp|
      issuers.push(sp.issuer)
    end

    airtable_api.get_matching_records(issuers).each do |record|
      unless airtable_api.new_partner_admin_in_airtable?(
        user.email, record
      )
        return false
      end
    end

    true
  end

  def partner_admin_confirmation_needed?
    return false unless IdentityConfig.store.prod_like_env

    return true if team.service_providers.empty?

    if team_membership.role_name == 'partner_admin'
      return false if params[:confirm_partner_admin].present?
      return true if !verified_partner_admin?
    end
    false
  end
end
