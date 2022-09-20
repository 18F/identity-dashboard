class Teams::UsersController < AuthenticatedController
   before_action -> { authorize team, policy_class: TeamUsersPolicy }

    def new
      @user = User.new
    end
  
    def create
      add_email = user_params[:email].downcase
      existing_user_emails = team.users.map(&:email)
      if existing_user_emails.include?(add_email)
        @user = User.new
        flash[:error] = "#{add_email} is already part of the team"
        render :new
      else
        @user = User.where(email: add_email).first || User.new(user_params)
        if team.update(users: team.users + [@user])
            flash[:success] = 'Success'
            redirect_to team_path(@team.id)
        else
            render :new
        end
      end
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
        team.users.delete(user)
        flash[:success] = I18n.t('teams.users.remove.success', email: user.email)
        redirect_to team_path(team.id)
      else
        render_401
      end
    end
  
    private

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
end
  
