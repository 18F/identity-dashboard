class Teams::UsersController < AuthenticatedController
   before_action -> { authorize team, policy_class: ManageUsersPolicy }

    def delete
      @team = team
      @user = UserTeam.find_by(user_id: params[:id], team_id: params[:team_id])
      render :delete
    end
  
    def destroy
      user = User.find_by(id: params[:id])
      return unless team.users.delete(user)
      flash[:success] = I18n.t('notices.user_deleted', email: user.email)
      redirect_to team_path(@team.id)
    end
  
    def none; end
  
    private
  
    def user_params
      params.require(:user).permit(:email)
    end

    def team
      @team ||= Team.includes(:users).find(params[:team_id])
    end
end
  
