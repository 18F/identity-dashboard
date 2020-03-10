# :reek:InstanceVariableAssumption
class TeamsController < AuthenticatedController
  before_action -> { authorize Team }, only: %i[index create new]
  before_action -> { authorize team }, only: %i[edit update destroy show]

  def new
    @team = Team.new
    @agencies = Agency.all
  end

  def create
    @team = Team.new(update_params_with_current_user)
    add_new_user
    
    if @team.save

      flash[:success] = 'Success'
      redirect_to team_path(@team.id)
    else
      render :new
    end
  end

  def edit
    @agencies = Agency.all
  end

  def update
    if @team.update(update_params_with_current_user)
      add_new_user
      flash[:success] = 'Success'
      redirect_to team_path(@team.id)
    else
      render :edit
    end
  end

  def destroy
    return unless @team.destroy
    flash[:success] = 'Success'
    redirect_to teams_path
  end

  def index
    includes = %i[users service_providers agency]
    @teams = if current_user.admin?
               Team.includes(*includes).all
             else
               current_user.teams.includes(*includes).all
             end
  end

  def show; end

  private

  def authorize_team
    authorize team
  end

  def team
    @team ||= Team.find(params[:id])
  end

  # :reek:DuplicateMethodCall
  def add_new_user
    new_user_email = new_user_params[:email]
    return if new_user_email.blank?

    user = User.find_by(email: new_user_email).presence || User.new(email: new_user_email)
    @team.users << user unless @team.users.include?(user)
  end

  def team_params
    params.require(:team).permit(:name, :agency_id, :description, user_ids: [])
  end

  def new_user_params
    params.require(:new_user).permit(:email)
  end

  def update_params_with_current_user
    if current_user.admin?
      team_params
    else
      team_params.merge('user_ids': (team_params[:user_ids] << current_user.id.to_s))
    end
  end
end
