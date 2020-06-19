class TeamsController < AuthenticatedController
  before_action -> { authorize Team }, only: %i[index create new all]
  before_action -> { authorize team }, only: %i[edit update destroy show]

  def new
    @team = Team.new
    @agencies = Agency.all
  end

  def create
    @team = Team.new(update_params_with_current_user)

    if @team.save
      flash[:success] = 'Success'
      redirect_to new_team_manage_user_path(@team.id)
    else
      render :new
    end
  end

  def edit
    @agencies = Agency.all
  end

  def update
    if @team.update(update_params_with_current_user)
      flash[:success] = 'Success'
      redirect_to team_path(@team.id)
    else
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

  def index
    includes = %i[users service_providers agency]
    @teams = current_user.teams.includes(*includes).all
  end

  def all
    includes = %i[users service_providers agency]
    @teams = Team.includes(*includes).all

    render 'teams/all'
  end

  def show; end

  private

  def team
    @team ||= Team.find(params[:id])
  end

  def team_params
    params.require(:team).permit(:name, :agency_id, :description, user_ids: [])
  end

  def update_params_with_current_user
    if current_user.admin?
      team_params
    else
      user_ids = team_params[:user_ids] || []
      team_params.merge('user_ids': (user_ids << current_user.id.to_s))
    end
  end
end
