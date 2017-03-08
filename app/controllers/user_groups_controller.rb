class UserGroupsController < ApplicationController
  before_action -> { authorize UserGroup }
  before_action :find_user_group, only: [:show, :edit, :update, :destroy]

  def new
    @user_group = UserGroup.new
  end

  def create
    @user_group = UserGroup.new(user_group_params)

    if @user_group.save
      flash[:success] = 'Success'
      redirect_to user_groups_path
    else
      render :new
    end
  end

  def edit; end

  def update
    if @user_group.update(user_group_params)
      flash[:success] = 'Success'
      redirect_to user_groups_path
    else
      render :edit
    end
  end

  def destroy
    return unless @user_group.destroy
    flash[:success] = 'Success'
    redirect_to user_groups_path
  end

  def index
    @user_groups = UserGroup.all
  end

  private

  def find_user_group
    @user_group ||= UserGroup.find(params[:id])
  end

  def user_group_params
    params.require(:user_group).permit(:name, :description, user_ids: [])
  end
end
