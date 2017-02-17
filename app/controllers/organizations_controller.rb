class OrganizationsController < ApplicationController
  def index
    @organizations = Organization.all
  end

  def new
  end

  def create
    @organization = Organization.new(organiztion_params)
    if @organization.save!
      redirect_to @organization
    else
      render 'new'
    end
  end

  def update
    @organization = Organization.find(params[:id])
    if @organization.update(organiztion_params)
      redirect_to @organization
    else
      render 'edit'
    end
  end

  def show
    @organization = Organization.find(params[:id])
  end

  def edit
    @organization = Organization.find(params[:id])
  end

  def destroy
    @organization = Organization.find(params[:id])
    @organization.destroy
    redirect_to organizations_path
  end

  private
  def organiztion_params
    params.require(:organization).permit(:agency, :department, :team)
  end
end
