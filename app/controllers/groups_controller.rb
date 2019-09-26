class GroupsController < ApplicationController
  before_action -> { authorize Group }
  before_action :find_group, only: %i[show edit update destroy]

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
    if @group.update(group_params)
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

  def find_group
    @group ||= Group.find(params[:id])
  end

  def group_params
    params.require(:group).permit(:name, :agency_id, :description, user_ids: [])
  end
end
