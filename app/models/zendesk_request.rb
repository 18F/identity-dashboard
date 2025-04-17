require 'rails'

class ZendeskRequest
  ZENDESK_BASE_URL = 'https://logingov.zendesk.com'
  ZENDESK_POST_PATH = '/api/v2/requests.json'

  ZENDESK_TICKET_FORM_ID = 5663417357332

  ZENDESK_TICKET_FIELD_FUNCTIONS = {
    4418412738836 => -> (record) { record.agency.name.parameterize.underscore }, # Agency
    4417492827796 => -> (record) { record.app_name }, # Application Name
    5064895580308 => -> (record) { record.description }, # Ticket Description
    23180053076628 => -> (record) { record.issuer }, # Issuer
    20697165967508 => -> (record) { record.logo.present? }, # Logo attestation
    4417169610388 => -> (record) {
      IdentityConfig.store.prod_like_env ? 'integration_change' : 'new_integration'
    }, # Request type
    4418367585684 => -> (record) { 'on' }, # Ready to move to production attestation
  }

  # This is separete because the host isn't available in the model
  ZENDESK_PORTAL_URL_ID = 4417948129556
  ZENDESK_IAL_VALUE_ID = 4417494977300

  ZENDESK_TICKET_FIELD_INFORMATION = {
    4417940288916 => { label: 'application_url',
      placeholder: 'https://yourapp.gov/',
      input_type: 'text' },
    14323206118676 => { label: 'audience',
      placeholder: nil,
      input_type: 'select',
      options: [
        { label: 'Ganeral public', value: 'general_public' },
        { label: 'Federal civilian employee', value: 'federal_civilian_employee' },
        { label: 'Active duty U.S. military', value: 'active_duty_u.s._military' },
        { label: 'U.S. veteran', value: 'u.s._veteran' },
        { label: 'State or local employee', value: 'state_or_local_employee' },
        { label: 'Other', value: 'other' },
      ],
    },
    4417547364628 => { label: 'billing_pocs',
      placeholder: 'First Last - Director, Department - first.last@agency.gov - (555) 555-5555',
      input_type: 'text' },
    4417514509076 => { label: 'est_annual_reg',
      placeholder: 100000,
      input_type: 'number' },
    4417513940756 => { label: 'est_auths',
      placeholder: 50000,
      input_type: 'number' },
    4975909708564 => { label: 'help_desk_contact_info',
      placeholder: '(555) 555-5555 - support@agency.gov',
      input_type: 'text' },
    4417546214292 => { label: 'iaa_number',
      placeholder: 'LGABCFY210001-0001-0000',
      input_type: 'text' },
    4417512374548 => { label: 'launch_date',
      placeholder: nil,
      input_type: 'date' },
    14323273767572 => { label: 'monthly_active_users',
      placeholder: 20000,
      input_type: 'number' },
    4417948190868 => { label: 'pm_pocs',
      placeholder: 'First Last - Program Manager - first.last@agency.gov - (555) 555-5555',
      input_type: 'text' },
    14326923502100 => { label: 'seasonality',
      placeholder: nil,
      input_type: 'text' },
    4417940248340 => { label: 'tech_support_pocs',
      placeholder: 'First Last - Technical Lead - first.last@agency.gov - (555) 555-5555',
      input_type: 'text' },
  }

  attr_accessor :portal_url, :requestor, :service_provider, :conn

  def initialize(user, portal_url, service_provider)
    @requestor = user
    @portal_url = portal_url
    @service_provider = service_provider
  end

  def ticket_field_functions
    ZENDESK_TICKET_FIELD_FUNCTIONS
  end

  def build_zendesk_ticket(custom_fields)

    custom_fields << portal_url_value
    custom_fields << ial_value

    ticket_data = {
      request:  {
        requester: {
          name: "#{@requestor.first_name} #{@requestor.last_name}",
          email: @requestor.email,
        },
        subject: ticket_subject,
        comment: {
          body: ticket_body,
        },
        ticket_form_id: ZENDESK_TICKET_FORM_ID,
        custom_fields: custom_fields,
      },
    }
  end

  def ticket_subject
    "Deploy #{@service_provider.friendly_name} to Production"
  end

  def ticket_body
    "Please deploy #{@service_provider.friendly_name} to the Login.gov Production Environment"
  end

  def portal_url_value
    { id: ZENDESK_PORTAL_URL_ID, value: @portal_url }
  end

  def ial_value
    ial_value = case @service_provider.ial
    when 1, nil
      I18n.t('service_provider_form.zendesk_ticket.ial_option_1')
    when 2
      I18n.t('service_provider_form.zendesk_ticket.ial_option_2')
    end
    { id: ZENDESK_IAL_VALUE_ID, value: ial_value }
  end

  def create_ticket(ticket_data)
    headers = { 'Content-Type' => 'application/json' }

    @conn ||= Faraday.new(url: ZENDESK_BASE_URL, headers: headers)

    resp = @conn.post(ZENDESK_POST_PATH) { |req| req.body = ticket_data.to_json }
    response = JSON.parse(resp.body)

    if resp.status == 201
      ticket_id = response.dig('request', 'id')
      { success: true, ticket_id: ticket_id }
    else
      errors = response.dig('details', 'base')
      if (errors)
        parsed_errors = []
        errors.each do |e|
          parsed_errors.push(e['description'])
        end
        return { success: false, errors: parsed_errors }
      end
      { success: false, errors: [] }
    end

  end
end
