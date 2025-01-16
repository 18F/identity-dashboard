class Teams::UsersController < AuthenticatedController
  before_action :authorize_manage_team_users,
                unless: -> { IdentityConfig.store.access_controls_enabled }

  def index
    authorize current_user_team_membership if IdentityConfig.store.access_controls_enabled
  end

  def new
    authorize current_user_team_membership if IdentityConfig.store.access_controls_enabled
    @user = User.new
  end

  def create
    if IdentityConfig.store.access_controls_enabled
      new_membership = UserTeam.build(team: team, user: new_member, role: new_member.primary_role)
      authorize new_membership
      new_membership.save!
      flash[:success] = I18n.t('teams.users.create.success', email: member_email)
      redirect_to new_team_user_path and return
    end
    new_member.user_teams << UserTeam.create!(user_id: new_member.id, group_id: team.id)
    flash[:success] = I18n.t('teams.users.create.success', email: member_email)
    redirect_to new_team_user_path and return
  rescue ActiveRecord::RecordInvalid => err
    flash[:error] = "'#{member_email}': " + err.record.errors.full_messages.join(', ')
    redirect_to new_team_user_path
  end

  def remove_confirm
    if IdentityConfig.store.access_controls_enabled
      membership_to_delete = UserTeam.find_by(user:, team:)
      authorize membership_to_delete
      return
    end

    if user_present_not_current_user(user)
      render :remove_confirm
    else
      render_401
    end
  end

  def destroy
    if IdentityConfig.store.access_controls_enabled
      # If unauthorized, the option to delete should not show up in the UI
      # so it is acceptable to return a 401 instead of a redirect here
      authorize UserTeam.find_by(user:, team:)
      team.users.delete(user)
      flash[:success] = I18n.t('teams.users.remove.success', email: user.email)
      redirect_to team_users_path and return
    end
    if user_present_not_current_user(user)
      team.users.delete(user)
      flash[:success] = I18n.t('teams.users.remove.success', email: user.email)
      redirect_to team_users_path
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

  def team
    @team ||= Team.includes(:users).find(params[:team_id])
  end

  def current_user_team_membership
    @current_user_team_membership ||= team.user_teams.find_by(user: current_user) || UserTeam.new
  end

  def authorize_manage_team_users
    authorize(
      current_user_team_membership,
      :manage_team_users?,
      policy_class: UserTeamPolicy,
    )
  end
end
