# Controller for Teams pages. Team Users has its own controller.
class TeamsController < AuthenticatedController # :nodoc:
  include ModelChanges

  before_action -> { authorize Team }, only: %i[index create new all]
  before_action -> { authorize team }, only: %i[edit update destroy show]
  after_action :log_change, only: %i[create update destroy]

  def index
    includes = %i[users service_providers agency]
    @teams = current_user.teams.includes(*includes).all
  end

  def show
    @audit_events = TeamAuditEvent.decorate(TeamAuditEvent.by_team(
      team,
      scope: policy_scope(PaperTrail::Version),
    ))
  end

  def new
    @team = Team.new
    @agencies = Agency.order(:name)
  end

  def edit
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
      redirect_to team_path(@team.id)
    else
      @agencies = Agency.order(:name)
      render :edit
    end
  end

  def destroy
    if @team.service_providers.empty? && @team.destroy
      flash[:success] = 'Success'
      return redirect_to teams_path
    end

    flash[:warning] = I18n.t('notices.team_delete_failed')
    redirect_back(fallback_location: teams_path)
  end

  def all
    includes = %i[users service_providers agency]
    @teams = Team.includes(*includes).all

    render 'teams/all'
  end

  private

  def team
    @team ||= Team.find(params[:id])
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
end
