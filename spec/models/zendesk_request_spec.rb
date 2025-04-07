require 'rails_helper'
require 'nokogiri'

describe ZendeskRequest do
  let(:user) { build(:user) }
  let(:sp) { build(:service_provider, :with_ial_1) }
  let(:zendesk_request) { ZendeskRequest.new(user, 'localhost', sp) }

  describe 'initialize' do
    it 'initializes' do
      expect(zendesk_request.requestor).to eq(user)
      expect(zendesk_request.host).to eq('localhost')
      expect(zendesk_request.service_provider).to eq(sp)
    end
  end

  describe 'build zendesk request' do
    it 'builds the ticket request data' do
      allow(zendesk_request).to receive(:portal_url).and_return({ id: ZendeskRequest::ZENDESK_PORTAL_URL_ID, value: 'https://portal.int.identitysandbox.gov/service_providers/1' })

      custom_fields = [{"id":4418367585684,"value":"on"},{"id":20697165967508,"value":"on"},{"id":4418412738836,"value":"General Services Administration"},{"id":4417546214292,"value":"LGMIA999999"},{"id":4417547364628,"value":"BillingPOC TestUser - test.user@gsa.gov - 555-555-1234"},{"id":4417948129556,"value":"https://portal.int.identitysandbox.gov/service_providers/9999"},{"id":23180053076628,"value":"urn:issuer:testing:gsa:test_application"},{"id":4417940288916,"value":"https://fakeapplication.gov/logingov"},{"id":4417492827796,"value":"Application Name - Testing Application"},{"id":5064895580308,"value":"Application Description"},{"id":14323206118676,"value":"General public"},{"id":4417514509076,"value":"100000"},{"id":14323273767572,"value":"1000"},{"id":14326923502100,"value":"All Year Seasonality"},{"id":4417513940756,"value":"1200000"},{"id":4417494977300,"value":"ial1"},{"id":4417512374548,"value":"2025-01-01"},{"id":4417948190868,"value":"PM Curcio - test.user@gsa.gov - 555-555-1234"},{"id":4417940248340,"value":"Techsupport Curcio - test.user@gsa.gov - 555-555-1234"},{"id":4975909708564,"value":"Helpdesk Contact Info"},{"id":4417169610388,"value":"new_integration"}]
      ticket_data = zendesk_request.build_zendesk_ticket(custom_fields)

      expected_response = {
      request:  {
        requester: {
          name: "#{user.first_name} #{user.last_name}",
          email: user.email,
        },
        subject: "Deploy #{sp.friendly_name} to Production",
        comment: {
          body: "Please deploy #{sp.friendly_name} to the Login.gov Production Environment",
        },
        ticket_form_id: ZendeskRequest::ZENDESK_TICKET_FORM_ID,
        custom_fields: custom_fields,
      },
    }

      expect(ticket_data).to eq(expected_response)
    end
  end

  describe 'ticket_subject' do
    it 'generates the proper ticket subject line' do
      subject = zendesk_request.ticket_subject
      expect(subject).to eq("Deploy #{sp.friendly_name} to Production")
    end
  end

  describe 'ticket_body' do
    it 'generates the proper ticket body' do
    description = zendesk_request.ticket_body
    expect(description).to eq("Please deploy #{sp.friendly_name} to the Login.gov Production Environment")
    end
  end

  describe 'portal_url' do
    it 'generates the correct portal url for the service provider' do
      # url = Rails.application.routes.url_helpers.service_provider_url(sp, host: zendesk_request.host)
      # { id: ZENDESK_PORTAL_URL_ID, value: url }
      # puts url
    end
  end

  describe 'ial_value' do
    it 'has an ial_value of 1' do
      sp.ial = 1
      sp.save
      ial = zendesk_request.ial_value
      expect(ial).to eq({id: ZendeskRequest::ZENDESK_IAL_VALUE_ID, value: 'ial1'})

    end
    it 'has an ial_value of 2' do
      sp.ial = 2
      sp.save
      ial = zendesk_request.ial_value
      expect(ial).to eq({id: ZendeskRequest::ZENDESK_IAL_VALUE_ID, value: 'idv'})
    end
  end
end
