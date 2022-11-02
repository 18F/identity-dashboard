class Teams::UsersController < AuthenticatedController
    before_action -> { authorize team, policy_class: TeamUsersPolicy }

    def new
      @user = User.new
    end
  
    def create
      add_email = user_params.require(:email).downcase
      @user = User.find_or_initialize_by(email: add_email)
      if team.users.include?(@user)
        @user = User.new
        flash[:error] = I18n.t('teams.users.create.already_member', email: add_email)
      elsif not @user.valid?
        flash[:error] = @user.errors.of_kind?(:email, :invalid) ?
                        I18n.t('teams.users.create.invalid_email', email: add_email) : 
                        @user.errors.objects.first.full_message
      elsif team.update(users: team.users + [@user])
        flash[:success] = I18n.t('teams.users.create.success', email: add_email)
        redirect_to team_path(team.id) and return
      end
      render :new
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
  
