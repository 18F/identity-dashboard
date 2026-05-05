# Controller for Teams pages. Team Users has its own controller.
class TeamsController < AuthenticatedController
  include ModelChanges

  WIZARD_STEPS = %i[new_team add_users team_details].freeze

  before_action -> { authorize Team }, only: %i[index create new all]
  before_action -> { authorize team }, only: %i[edit update destroy show]

  rescue_from ActiveRecord::RecordNotFound do
    render file: 'public/404.html', status: :not_found, layout: false
  end

  def index
    includes = %i[users service_providers agency]
    @teams = current_user.teams.includes(*includes).all
    update_return_path(nil)
  end

  def show
    @audit_events = TeamAuditEvent.decorate(
      TeamAuditEvent.by_team(
        team,
        scope: policy_scope(PaperTrail::Version),
      ),
    )
    @show_wizard = params[:wizard].present?
    @steps = WIZARD_STEPS
  end

  def new
    @team = Team.new
    update_agency_and_wizard_vars
  end

  def edit
    get_return_path
    @agencies = Agency.order(:name)
  end

  def create
    @team = Team.new(update_params_with_current_user)
    @team.uuid = SecureRandom.uuid

    log_change
    if @team.save
      current_user.grant_team_membership(@team, 'partner_admin')
      flash[:success] = "You have created #{@team.name}"
      redirect_to new_team_user_path(@team, wizard: true)
    else
      update_errors
      update_agency_and_wizard_vars
      render :new
    end
  end

  def update
    @team.assign_attributes(update_params_with_current_user)
    log_change
    if @team.save
      deploy_sandbox_agency_change
      flash[:success] = 'Success'
      redirect_to get_return_path
    else
      @agencies = Agency.order(:name)
      render :edit
    end
  end

  def destroy
    log_change
    if @team.service_providers.empty? && @team.destroy
      flash[:success] = 'Success'
      return redirect_to get_return_path
    end

    flash[:warning] = I18n.t('notices.team_delete_failed')
    redirect_back(fallback_location: get_return_path)
  end

  def all
    includes = %i[users service_providers agency]
    @teams = Team.includes(*includes).all
    update_return_path('all')

    render 'teams/all'
  end

  private

  def team
    @team ||= Team.find_by_id_or_uuid(params[:id]) # rubocop:disable Rails/DynamicFindBy

    return @team if @team

    raise(ActiveRecord::RecordNotFound) if current_user.logingov_staff?

    raise(Pundit::NotAuthorizedError, I18n.t('errors.not_authorized'))
  end

  def team_params
    params.require(:team).permit(:name, :agency_id, :description)
  end

  def existing_user_ids
    params[:user_ids]&.split(' ') || []
  end

  def update_params_with_current_user
    if current_user.logingov_admin?
      team_params
    else
      team_params.merge(user_ids: (existing_user_ids + [current_user.id.to_s]).uniq)
    end
  end

  def update_errors
    return unless @team.errors[:agency].present?

    @team.errors.add(:agency_id, @team.errors[:agency])
    @team.errors.delete(:agency)
  end

  def update_agency_and_wizard_vars
    @show_wizard = true
    @steps = WIZARD_STEPS
    @agencies = Agency.order(:name)
  end

  def deploy_sandbox_agency_change
    return if IdentityConfig.store.prod_like_env || !team.saved_change_to_agency_id

    team.service_providers.each do |sp|
      next unless ServiceProviderUpdater.post_update(
        { service_provider: ServiceProviderSerializer.new(sp) },
      ) != 200

      flash[:error] = I18n.t('notices.agency_update_sp_refresh_failed')
    end
  end

  def log_change
    # TODO: Log error if @team is not valid
    return unless @team.present?

    if action_name == 'create'
      log.team_created(changes:)
    elsif action_name == 'destroy'
      log.team_destroyed(changes:)
    else
      log.team_updated(changes:)
    end
  end

  def changes
    changes_to_log(@team)
  end

  def get_return_path
    @teams_return_path = session[:team_return] == 'all' ? teams_all_path : teams_path
  end

  def update_return_path(path_suffix)
    session[:team_return] = path_suffix
  end
end
