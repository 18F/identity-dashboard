# Controller for Teams pages. Team Users has its own controller.
class TeamsController < AuthenticatedController
  include ModelChanges

  before_action -> { authorize Team }, only: %i[index create new all]
  before_action -> { authorize team }, only: %i[edit update destroy show]
  after_action :log_change, only: %i[create update destroy]

  def index
    includes = %i[users service_providers agency]
    @teams = current_user.teams.includes(*includes).all
    team_return_tracker.set('index')
    config_return_tracker.set('team_index')
  end

  def show
    @audit_events = TeamAuditEvent.decorate(TeamAuditEvent.by_team(
      team,
      scope: policy_scope(PaperTrail::Version),
    ))
    config_return_tracker.set("team,#{team.id}")
  end

  def new
    @team = Team.new
    @agencies = Agency.order(:name)
  end

  def edit
    @teams_return_path = team_return_tracker.path
    @agencies = Agency.order(:name)
  end

  def create
    @team = Team.new(update_params_with_current_user)
    @team.uuid = SecureRandom.uuid

    if @team.save
      current_user.grant_team_membership(@team, 'partner_admin')
      flash[:success] = 'Success'
      redirect_to team_users_path(@team.id)
    else
      @agencies = Agency.order(:name)
      render :new
    end
  end

  def update
    if @team.update(update_params_with_current_user)
      flash[:success] = 'Success'
      redirect_to team_return_tracker.path
    else
      @agencies = Agency.order(:name)
      render :edit
    end
  end

  def destroy
    if @team.service_providers.empty? && @team.destroy
      flash[:success] = 'Success'
      return redirect_to team_return_tracker.path
    end

    flash[:warning] = I18n.t('notices.team_delete_failed')
    redirect_back(fallback_location: team_return_tracker.path)
  end

  def all
    includes = %i[users service_providers agency]
    @teams = Team.includes(*includes).all
    team_return_tracker.set('all')

    render 'teams/all'
  end

  private

  def team
    @team ||= Team.find_by_id_or_uuid(params[:id]) # rubocop:disable Rails/DynamicFindBy
    @team ||= Team.new
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

  def team_return_tracker
    @team_return_tracker ||= ReturnTracker.new(session, :team)
  end

  def config_return_tracker
    @config_return_tracker ||= ReturnTracker.new(session, :config)
  end
end
