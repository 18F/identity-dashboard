class GroupsController < ApplicationController
  before_action -> { authorize Group }
  before_action :find_group, only: %i[show edit update destroy]

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(group_params)

    if @group.save
      flash[:success] = 'Success'
      redirect_to groups_path
    else
      render :new
    end
  end

  def edit; end

  def update
    if @group.update(group_params)
      flash[:success] = 'Success'
      redirect_to groups_path
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

  private

  def find_group
    @group ||= Group.find(params[:id])
  end

  def group_params
    params.require(:group).permit(:name, :description, user_ids: [])
  end
end
