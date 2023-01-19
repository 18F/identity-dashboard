class Teams::UsersController < AuthenticatedController
  before_action -> { authorize team, policy_class: TeamUsersPolicy }

  def new
    @user = User.new
  end

  def create
    new_member.user_teams << UserTeam.create!(user_id: new_member.id, group_id: team.id)
    flash[:success] = I18n.t('teams.users.create.success', email: member_email)
    redirect_to team_path(team.id) and return
  rescue ActiveRecord::RecordInvalid => e
    flash[:error] = "Email '#{member_email}': " + e.record.errors.full_messages.join(', ')
    redirect_to new_team_user_path
  end

  def remove_confirm
    if user_present_not_current_user(user)
      render :remove_confirm
    else
      render_401
    end
  end

  def destroy
    if user_present_not_current_user(user)
      team_and_users.users.delete(user)
      flash[:success] = I18n.t('teams.users.remove.success', email: user.email)
      redirect_to team_path(team.id)
    else
      render_401
    end
  end

  private

  def member_email
    user_params.require(:email).downcase
  end

  def new_member
    @new_member ||= User.find_or_create_by!(email: member_email)
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

  def team_and_users
    @team ||= Team.includes(:users).find(params[:team_id])
  end

  def team
    @team ||= Team.find(params[:team_id])
  end
end
