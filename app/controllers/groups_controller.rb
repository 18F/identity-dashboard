# :reek:InstanceVariableAssumption
class GroupsController < AuthenticatedController
  before_action -> { authorize Group }, only: %i[index create new]
  before_action -> { authorize group }, only: %i[edit update destroy show]

  def new
    @group = Group.new
    @agencies = Agency.all
  end

  def create
    @group = Group.new(group_params)

    if @group.save

      flash[:success] = 'Success'
      redirect_to group_path(@group.id)
    else
      render :new
    end
  end

  def edit
    @agencies = Agency.all
  end

  def update
    update_params = current_user.admin? ? group_params : group_params.merge('user_ids': current_user.id.to_s)
    if @group.update(update_params)
      add_new_user
      flash[:success] = 'Success'
      redirect_to group_path(@group.id)
    else
      render :edit
    end
  end

  def destroy
    return unless @group.destroy
    flash[:success] = 'Success'
    redirect_to groups_path
  end

  def index
    @groups = Group.includes(:users).all
  end

  def show; end

  private

  def authorize_group
    authorize group
  end

  def group
    @group ||= Group.find(params[:id])
  end

  # :reek:DuplicateMethodCall
  def add_new_user
    new_user_email = new_user_params[:email]
    return if new_user_email.blank?

    user = User.find_by(email: new_user_email).presence || User.new(email: new_user_email)
    @group.users << user unless @group.users.include?(user)
  end

  def group_params
    params.require(:group).permit(:name, :agency_id, :description, user_ids: [])
  end

  def new_user_params
    params.require(:new_user).permit(:email)
  end
end
