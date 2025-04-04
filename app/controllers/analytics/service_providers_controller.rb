class Analytics::ServiceProvidersController < ApplicationController
  before_action -> { authorize User, policy_class: AnalyticsPolicy }

  def show
    @issuer = service_provider.issuer
     @friendly_name = service_provider.friendly_name.capitalize
  end

  private

  def service_provider
    @service_provider ||= ServiceProvider.includes(:agency,
logo_file_attachment: :blob).find(id)
  end

  def id
    @id ||= params[:id]
  end
end

