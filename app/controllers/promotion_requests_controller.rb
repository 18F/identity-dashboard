# Handle requests to Zendesk for specific ServiceProvider records
class PromotionRequestsController < AuthenticatedController
  before_action -> { authorize(service_provider || ServiceProvider, :prod_request?) }

  after_action :verify_authorized
  after_action :verify_policy_scoped

  def create
    zendesk_response = make_zendesk_request({ service_provider: create_params })

    log.zendesk_response(zendesk_response)
    flash_zendesk_status(zendesk_response)
    redirect_to service_provider_path(@service_provider.id)
  end

  private

  def create_params
    params.require(:service_provider).permit(
      :id,
      ZendeskRequest::ZENDESK_PORTAL_URL_ID.to_s,
      ZendeskRequest::ZENDESK_IAL_VALUE_ID.to_s,
      *ZendeskRequest::ZENDESK_TICKET_FIELD_FUNCTIONS.keys.map(&:to_s),
      *ZendeskRequest::ZENDESK_TICKET_FIELD_INFORMATION.keys.map(&:to_s),
    )
  end

  def service_provider
    @service_provider ||= policy_scope(ServiceProvider).find_by_id_or_uuid( # rubocop:disable Rails/DynamicFindBy
      params[:service_provider][:id],
    )
  end

  def make_zendesk_request(params)
    zendesk_request = ZendeskRequest.new(current_user, portal_url, service_provider)
    zendesk_request.add_fields_from_params(params)

    zendesk_request.create_ticket
  end

  def portal_url
    Rails.application.routes.url_helpers.service_provider_url(
      service_provider,
      host: request.host,
    )
  end

  def flash_zendesk_status(zendesk_response)
    if zendesk_response[:status] == :success
      flash[:success] = "Request submitted successfully. Ticket ##{zendesk_response[:ticket_id]} \
        has been created on your behalf, replies will be sent to #{current_user.email}."
    else
      errors = zendesk_response[:errors]
      test_value = [errors.initial_text, *errors.remaining_text]
      flash[:error] = test_value
    end
  end
end
