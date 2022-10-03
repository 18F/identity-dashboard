class Teams::UsersController < AuthenticatedController
   before_action -> { authorize team, policy_class: TeamUsersPolicy }

    def remove_confirm
      @team = team
      @user = team.users.find_by(id: params[:id])
      if @user.present?
        render :remove_confirm      
      else
        render_401
      end
    end
  
    def destroy
      user = team.users.find_by(id: params[:id])
      if user.present?
        team.users.delete(user)
        flash[:success] = I18n.t('team.users.remove_success', email: user.email)
        redirect_to team_path(@team.id)
      else
        render_401
      end
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
  
