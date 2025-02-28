class TeamsController < AuthenticatedController
  before_action -> { authorize Team }, only: %i[index create new all]
  before_action -> { authorize team }, only: %i[edit update destroy show]

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
    @agencies = Agency.all.order(:name)
  end

  def edit
    @agencies = Agency.all.order(:name)
  end

  def create
    @team = Team.new(update_params_with_current_user)

    if @team.save
      flash[:success] = 'Success'
      redirect_to team_users_path(@team.id)
    else
      @agencies = Agency.all.order(:name)
      render :new
    end
  end

  def update
    if @team.update(update_params_with_current_user)
      flash[:success] = 'Success'
      redirect_to team_path(@team.id)
    else
      @agencies = Agency.all.order(:name)
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
end
