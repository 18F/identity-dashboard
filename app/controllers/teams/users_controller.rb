# Controls Team Users pages, where partners update the users for a given team
class Teams::UsersController < AuthenticatedController
  include ModelChanges

  after_action :verify_authorized
  after_action :verify_policy_scoped

  helper_method :roles_for_options, :show_actions?

  rescue_from AbstractController::ActionNotFound do
    render file: 'public/404.html', status: :not_found, layout: false
  end

  def index
    authorize current_team_membership
    @team_memberships = team && team.team_memberships.where
      .associated(:user, :team)
      .includes(:user)
      .order('users.email')
    @team_memberships ||= []
  end

  def show
    raise AbstractController::ActionNotFound
  end

  def new
    verify_airtable_connection

    authorize current_team_membership
    @user = policy_scope(User).new
    @show_wizard = params[:wizard].present?
    @steps = TeamsController::WIZARD_STEPS
  end

  def edit
    @needs_to_confirm_partner_admin = params[:need_to_confirm_role].present?
    verify_airtable_connection

    authorize team_membership
    @user = team_membership.user
  end

  def create
    users_params = params.require(:users).map { |u| u.permit(:email, :role_name) }
    @errors = []
    @users_data = users_params.map(&:to_h)
    team
    authorize TeamMembership.new(team:), :create?

    needs_confirmation = confirmation_needed_entries(users_params)
    created_memberships = needs_confirmation.empty? ? save_team_memberships(users_params) : []

    if @errors.any? || needs_confirmation.any?
      render_new_with_confirmation(needs_confirmation) and return
    end

    redirect_after_create(created_memberships)
  rescue ActiveRecord::RecordInvalid => err
    redirect_with_duplicate_email_error(err)
  end

  def update
    team_membership.assign_attributes(team_membership_params)
    authorize team_membership

    if IdentityConfig.store.prod_like_env && partner_admin_confirmation_needed?
      flash[:error] = partner_admin_not_verified_message(team_membership.user.email)

      redirect_to edit_team_user_path(team, team_membership.user,
                                      need_to_confirm_role: true) and return
    end
    log_change
    team_membership.save
    if team_membership.errors.any?
      @user = team_membership.user
      render :edit
    end
    new_role_name = t("role_names.#{
      IdentityConfig.store.prod_like_env ? 'production' : 'sandbox'
    }.#{team_membership.role_name}")
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
    membership = team_membership || policy_scope(TeamMembership).build(team: team)
    roles = policy(membership).roles_for_edit
    if IdentityConfig.store.prod_like_env && !partner_admin_role_available?
      roles = roles.reject { |role| role.name == 'partner_admin' }
    end
    roles.map { |r| [r.friendly_name, r.name] }
  end

  def show_actions?
    @team_memberships.any? { |membership| policy(membership).destroy? || policy(membership).edit? }
  end

  private

  def confirmation_needed_entries(users_params)
    return [] if params[:confirm_partner_admin].present?

    users_params.select { |u| partner_admin_confirmation_needed_for_create?(u) }
  end

  def save_team_memberships(users_params)
    created_memberships = []
    users_params.each do |user_entry|
      membership = build_team_membership(user_entry)
      next unless membership

      if membership.save
        created_memberships << membership
      else
        @errors << { messages: membership_error_messages(membership) }
      end
    end
    created_memberships
  end

  def render_new_with_confirmation(needs_confirmation)
    @show_wizard = params[:wizard].present?
    @steps = TeamsController::WIZARD_STEPS
    @needs_confirmation = needs_confirmation
    render :new
  end

  def redirect_after_create(created_memberships)
    emails = created_memberships.map { |m| m.user.email }.join(', ')
    flash[:success] = I18n.t('teams.users.create.success', email: emails)
    if params[:wizard].present?
      redirect_to team_path(team, wizard: true)
    else
      redirect_to team_users_path(team)
    end
  end

  def redirect_with_duplicate_email_error(err)
    email_taken_error = [:user_id, :taken]
    error_messages = err.record.errors.map do |record_error|
      if email_taken_error == [record_error.attribute, record_error.type]
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

  def build_team_membership(user_entry)
    email = user_entry[:email]&.downcase
    new_user = User.find_or_create_by(email: email)

    unless new_user.valid?
      @errors << { messages: new_user.errors.full_messages }
      return nil
    end

    membership = policy_scope(TeamMembership).build(team: team, user: new_user)

    if user_entry[:role_name].present?
      membership.role_name = user_entry[:role_name]
    else
      membership.set_default_role
    end

    authorize membership
    @team_membership = membership
    log_change
    membership
  end

  def membership_error_messages(membership)
    membership.errors.map do |error|
      if error.attribute == :user_id && error.type == :taken
        I18n.t(
          'activerecord.errors.models.team_membership.attributes.user_id.taken',
          value: membership.user.email,
        )
      else
        error.full_message
      end
    end
  end

  def user
    @user ||= team.users.find_by(id: params[:id])
  end

  def user_present_not_current_user(user)
    user.present? && user != current_user
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

  def partner_admin_role_available?
    return true if IdentityConfig.store.salesforce_api_enabled

    Airtable.new(current_user.uuid).has_token?
  end

  def verified_partner_admin?(email)
    if IdentityConfig.store.salesforce_api_enabled
      verified_partner_admin_in_salesforce?(email)
    else
      verified_partner_admin_in_airtable?(email)
    end
  end

  def verified_partner_admin_in_salesforce?(email)
    salesforce_service.partner_admin_for_team?(team.uuid, email)
  rescue StandardError
    false
  end

  def salesforce_service
    @salesforce_service ||= SalesforceService.new
  end

  def verified_partner_admin_in_airtable?(email)
    airtable_api = Airtable.new(current_user.uuid)
    airtable_api.refresh_token_if_needed(request)
    issuers = []
    ServiceProvider.where(team: team).each do |sp|
      issuers.push(sp.issuer)
    end

    matched_records = airtable_api.get_matching_records(issuers)

    return false if matched_records.empty?

    matched_records.any? do |record|
      airtable_api.new_partner_admin_in_airtable?(email, record)
    end
  end

  def partner_admin_confirmation_needed?
    # Logingov Admin is confirming now
    return false if params[:confirm_partner_admin].present?

    # Only check with Airtable/Salesforce in Prod Like Environments
    return false unless IdentityConfig.store.prod_like_env

    # More checks needed if role is being set to partner_admin.
    if team_membership.role_name == 'partner_admin'
      return partner_admin_confirmation_needed_for_email?(team_membership.user.email)
    end

    false
  end

  def partner_admin_confirmation_needed_for_create?(user_entry)
    return false unless IdentityConfig.store.prod_like_env
    return false unless IdentityConfig.store.salesforce_api_enabled
    return false unless user_entry[:role_name] == 'partner_admin'
    return false if user_entry[:email].blank?

    partner_admin_confirmation_needed_for_email?(user_entry[:email])
  end

  def partner_admin_confirmation_needed_for_email?(email)
    return true if team.service_providers.empty?

    !verified_partner_admin?(email.downcase)
  end

  def partner_admin_not_verified_message(email)
    external_provider = IdentityConfig.store.salesforce_api_enabled ? 'Salesforce' : 'Airtable'
    partner_admin_name = t('role_names.production.partner_admin')

    "User #{email} is not a verified #{partner_admin_name} in #{external_provider}. " \
      'Please verify with the appropriate Account Manager that this user should ' \
      "be given the #{partner_admin_name} role."
  end

  def verify_airtable_connection
    return unless policy(:airtable).index?

    airtable_api = Airtable.new(current_user.uuid)
    return if airtable_api.has_token?

    @remove_partner_admin = true
    airtable_api.refresh_token_if_needed(request)

    base_url = "#{request.protocol}#{request.host_with_port}"
    @oauth_url = airtable_api.generate_oauth_url(base_url)
  end
end
