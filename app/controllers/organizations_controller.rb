class OrganizationsController < ApplicationController
  before_action :authorize_admin_user
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

  def new_user
    org = Organization.find(params[:id])
    user = User.find(params.require(:user).require(:id))
    user.organization_id = org.id
    user.save!
    redirect_to org
  end

  def new_service_provider
    org = Organization.find(params[:id])
    sp = find_sp(params)
    if sp
      sp.organization_id = org.id
      sp.save!
    end
    redirect_to org
  end

  def remove_user
    org = Organization.find(params[:id])
    user = User.find(params.require(:user_id))
    if user
      user.organization_id = nil
      user.save!
    end
    redirect_to org
  end

  def remove_service_provider
    org = Organization.find(params[:id])
    sp = ServiceProvider.find(params.require(:service_provider_id))
    if sp
      sp.organization_id = nil
      sp.save!
    end
    redirect_to org
  end

  private
  def find_sp(params)
    if params[:service_provider][:id].present?
      ServiceProvider.find(params.require(:service_provider).require(:id))
    end
  end

  def organiztion_params
    params.require(:organization).permit(:agency, :department, :team)
  end

  def authorize_admin_user
    unless current_user && current_user.admin?
      raise Pundit::NotAuthorizedError, I18n.t('errors.not_authorized')
    end
  end
end
