class OrganizationsController < ApplicationController
  before_action -> { authorize Organization }
  before_action :find_organization, only: [:show, :edit, :update, :destroy]

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(organization_params)

    if @organization.save
      flash[:success] = 'Success'
      redirect_to @organization
    else
      render :new
    end
  end

  def show; end

  def edit; end

  def update
    if @organization.update(organization_params)
      flash[:success] = 'Success'
      redirect_to @organization
    else
      render :edit
    end
  end

  def destroy
    return unless @organization.destroy
    flash[:success] = 'Success'
    redirect_to organizations_path
  end

  def index
    @organizations = Organization.all
  end

  private

  def find_organization
    @organization ||= Organization.find(params[:id])
  end

  def organization_params
    params.require(:organization).permit(:agency_name, :department_name, :team_name)
  end
end
