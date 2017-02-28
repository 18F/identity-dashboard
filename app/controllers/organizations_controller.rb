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
    if organization.update(organiztion_params)
      redirect_to organization
    else
      render 'edit'
    end
  end

  def show
    organization
  end

  def edit
    organization
  end

  def destroy
    if organization.service_providers.empty? && organization.users.empty?
      organization.destroy
      redirect_to organizations_path
    else
      flash[:error] = "You must remove all users and service providers before deleting an organization."
      redirect_to organization
    end
  end

  def new_user
    user = User.find(params.require(:user).require(:id))
    user.organization = organization
    user.save!
    redirect_to organization
  end

  def new_service_provider
    sp = find_sp(params)
    if sp
      sp.organization = organization
      sp.save!
    end
    redirect_to organization
  end

  def remove_user
    user = User.find(params.require(:user_id))
    if user
      user.organization = nil
      user.save!
    end
    redirect_to organization
  end

  def remove_service_provider
    sp = ServiceProvider.find(params.require(:service_provider_id))
    if sp
      sp.organization = nil
      sp.save!
    end
    redirect_to organization
  end

  private
  def organization
    @organization ||= Organization.find(params[:id])
  end

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
