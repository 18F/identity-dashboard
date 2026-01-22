# Controls Team Users pages, where partners update the users for a given team
class Teams::UsersController < AuthenticatedController
  include ModelChanges

  after_action :verify_authorized
  after_action :verify_policy_scoped

  helper_method :roles_for_options, :show_actions?

  def index
    authorize current_team_membership
    @team_memberships = team && team.team_memberships.where
      .associated(:user, :team)
      .includes(:user)
      .order('users.email')
    @team_memberships ||= []
  end

  def new
    authorize current_team_membership
    @user = policy_scope(User).new
  end

  def edit
    if IdentityConfig.store.prod_like_env
      airtable_api = Airtable.new(current_user.uuid)
      if airtable_api.has_token?
        @needs_to_confirm_partner_admin = true if params[:need_to_confirm_role]
      else
        @remove_partner_admin = true
        airtable_api.refresh_token if airtable_api.needs_refreshed_token?

        base_url = "#{request.protocol}#{request.host_with_port}"
        @oauth_url = airtable_api.generate_oauth_url(base_url)
      end
    end

    authorize team_membership
    @user = team_membership.user
  end

  def create
    unless new_team_member.valid?
      team
      authorize TeamMembership.new(team:), :create?
      render(:new) and return
    end

    new_team_membership = policy_scope(TeamMembership).build(
      team: team,
      user: new_team_member,
    )
    new_team_membership.set_default_role
    authorize new_team_membership
    @team_membership = new_team_membership
    log_change
    render :new and return unless new_team_membership.save!

    flash[:success] = I18n.t('teams.users.create.success', email: member_email)
    redirect_to new_team_user_path
  rescue ActiveRecord::RecordInvalid => err
    error_messages = err.record.errors.map do |record_error|
      if [:user_id, :taken] == [record_error.attribute, record_error.type]
        I18n.t(
          'activerecord.errors.models.team_membership.attributes.user_id.taken',
          value: "<strong>#{err.record.user.email}</strong>",
        )
      else
        record_error
      end
    end.join(', ')
    flash[:error] = "<p class='usa-alert__text'>#{error_messages}</p>"
    redirect_to new_team_user_path
  end

  def update
    team_membership.assign_attributes(team_membership_params)
    authorize team_membership

    if IdentityConfig.store.prod_like_env && partner_admin_confirmation_needed?
      flash[:error] =
        "User #{team_membership.user.email} is not a #{
            t('role_names.production.partner_admin')
          } in Airtable.
          Please verify with the appropriate Account Manager that this user should
          be given the #{t('role_names.production.partner_admin')} role."

      redirect_to edit_team_user_path(team, team_membership.user,
                                      need_to_confirm_role: true) and return
    end
    log_change
    team_membership.save
    if team_membership.errors.any?
      @user = team_membership.user
      render :edit
    end
    new_role_name = t("role_names.sandbox.#{team_membership.role_name}")
    flash[:success] =
      I18n.t(
        'teams.users.update.success_html',
        email: team_membership.user.email,
        new_role_name:,
      )
    redirect_to team_users_path(team)
  end

  def remove_confirm
    team_membership_to_delete = policy_scope(TeamMembership).find_by(user:, team:)
    authorize team_membership_to_delete
  end

  def destroy
    # If unauthorized, the option to delete should not show up in the UI
    # so it is acceptable to return a 401 instead of a redirect here
    authorize policy_scope(TeamMembership).find_by(user:, team:)
    log_change
    team.users.delete(user)
    flash[:success] = I18n.t('teams.users.remove.success', email: user.email)
    redirect_to team_users_path
  end

  def roles_for_options
    roles = policy(team_membership).roles_for_edit
    if IdentityConfig.store.prod_like_env && !Airtable.new(current_user.uuid).has_token?
      roles = roles.reject { |role| role.name == 'partner_admin' }
    end
    roles.map { |r| [r.friendly_name, r.name] }
  end

  def show_actions?
    @team_memberships.any? { |membership| policy(membership).destroy? || policy(membership).edit? }
  end

  private

  def member_email
    user_params[:email]&.downcase
  end

  def new_team_member
    @new_team_member ||= User.find_or_create_by(email: member_email)
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
    @team ||= policy_scope(Team).find_by_id_or_uuid(params[:team_id]) # rubocop:disable Rails/DynamicFindBy
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

  def log_change
    # TODO: Log error if team_membership is not valid
    return unless team_membership.present?

    if action_name == 'create'
      log.team_membership_created(changes:)
    elsif action_name == 'update'
      # do not log if there are no pending changes
      return if team_membership.changes.empty?

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
    airtable_api = Airtable.new(current_user.uuid)
    redirect_uri = airtable_api.build_redirect_uri(request)
    airtable_api.refresh_token(redirect_uri) if airtable_api.needs_refreshed_token?
    issuers = []
    ServiceProvider.where(team: team).each do |sp|
      issuers.push(sp.issuer)
    end
    
    matched_records = airtable_api.get_matching_records(issuers)

    return false if matched_records.empty?

    matched_records.each do |record|
      airtable_api.new_partner_admin_in_airtable?(user.email, record)
    end
  end

  def partner_admin_confirmation_needed?
    # Logingov Admin is confirming now
    return false if params[:confirm_partner_admin].present?

    # Only check with Airtable in Prod Like Environments
    return false unless IdentityConfig.store.prod_like_env

    # More checks needed if role is being set to partner_admin.
    if team_membership.role_name == 'partner_admin'
      # Confirmation needed when there is no service providers associated
      # with the team.
      return true if team.service_providers.empty?
      # Confirmation needed if the edited user is not a listed Partner
      # Admin in Airtable for the Service Providers associated with the team
      return true unless verified_partner_admin?
    end
    false
  end
end
