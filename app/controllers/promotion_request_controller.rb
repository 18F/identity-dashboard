# Handle requests to Zendesk for specific ServiceProvider records
class PromotionRequestController < AuthenticatedController
  before_action -> { authorize(service_provider || ServiceProvider, :prod_request?) }

  after_action :verify_authorized
  after_action :verify_policy_scoped

  def update
    creation_status = make_zendesk_request(params)
    flash_zendesk_status(creation_status)
    redirect_to action: 'show', id: @service_provider.id

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

    ticket_custom_fields = []
    zendesk_request.ticket_field_functions.each_with_object({}) do |(id, func), _result|
      ticket_custom_fields.push({
        id: id,
        value: func.to_proc.call(@service_provider),
      })
    end

    ZendeskRequest::ZENDESK_TICKET_FIELD_INFORMATION.each_key do |key|
      ticket_custom_fields.push({ id: key, value: params[:service_provider][key.to_s.to_sym] })
    end

    ticket_data = zendesk_request.build_zendesk_ticket(ticket_custom_fields)

    zendesk_request.create_ticket(ticket_data)
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
