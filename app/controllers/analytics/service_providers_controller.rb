class Analytics::ServiceProvidersController < ApplicationController # :nodoc:
  before_action -> { authorize User, policy_class: AnalyticsPolicy }
  # analtyics/service/providers/{id}
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
