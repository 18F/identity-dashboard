# Handle requests to Zendesk for specific ServiceProvider records
class PromotionRequestController < AuthenticatedController
  before_action -> { authorize(service_provider || ServiceProvider, :prod_request?) }

  after_action :verify_authorized
  after_action :verify_policy_scoped

  def update
    zendesk_status = make_zendesk_request(params)

    flash_zendesk_status(zendesk_status)
    redirect_to service_provider_path(@service_provider.id)
  end

  private

  def service_provider
    @service_provider ||= policy_scope(ServiceProvider).find_by_id_or_uuid(params[:service_provider][:id]) # rubocop:disable Rails/DynamicFindBy
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

  def flash_zendesk_status(creation_status)
    if creation_status[:success] == true
      flash[:success] = "Request submitted successfully. Ticket ##{creation_status[:ticket_id]} \
        has been created on your behalf, replies will be sent to #{current_user.email}."
    else
      errors = creation_status[:errors]
      flash[:error] = helpers.wrap_in_p_tag(errors.initial_text, css_class: 'usa-alert__text') +
                      helpers.wrap_in_p_tag(errors.remaining_text)
    end
  end
end
