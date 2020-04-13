class AddUsersController < AuthenticatedController
  before_action -> { authorize team, policy_class: AddUsersPolicy }

  def new; end

  def create; end

  private

  def team
    @team ||= Team.includes(:users).find(params[:team_id])
  end

  def add_users_params
    params.permit(:users)
  end
end
