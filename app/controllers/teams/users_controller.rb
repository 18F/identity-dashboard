class Teams::UsersController < AuthenticatedController
   before_action -> { authorize team, policy_class: TeamUsersPolicy }

    def remove_confirm
      @user = find_user_by_team
      if user_present_not_current_user(@user)
        render :remove_confirm      
      else
        render_401
      end
    end
  
    def destroy
      user = find_user_by_team
      if user_present_not_current_user(user)
        team.users.delete(user)
        flash[:success] = I18n.t('team.users.remove_success', email: user.email)
        redirect_to team_path(team.id)
      else
        render_401
      end
    end
  
    private

    def find_user_by_team
      team.users.find_by(id: params[:id])
    end

    def user_present_not_current_user(user)
      user.present? && user != current_user
    end

    def team
      @team ||= Team.includes(:users).find(params[:team_id])
    end
end
  
