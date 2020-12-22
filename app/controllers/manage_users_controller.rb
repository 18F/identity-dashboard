class ManageUsersController < AuthenticatedController
  before_action -> { authorize team, policy_class: ManageUsersPolicy }

  def new
    @manage_users_form = ManageUsersForm.new(team)
  end

  def create
    @manage_users_form = ManageUsersForm.new(team)
    user_emails = params[:user_emails] || []
    if @manage_users_form.submit(user_emails: user_emails)
      flash[:success] = 'Success'
      redirect_to team_path(@team.id)
    else
      render :new
    end
  end

  private

  def team
    @team ||= Team.includes(:users).find(params[:team_id])
  end
end
