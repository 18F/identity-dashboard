require 'rails_helper'
require 'nokogiri'

describe ZendeskRequest do
  let(:user) { build(:user) }
  let(:sp) { build(:service_provider, :with_ial_1) }
  let(:portal_url) { 'https://portal.int.identitysandbox.gov/service_providers/9999' }
  let(:zendesk_request) { ZendeskRequest.new(user, portal_url, sp) }
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:conn) { Faraday.new(url: ZendeskRequest::ZENDESK_BASE_URL) { |b| b.adapter(:test, stubs) } }
  # rubocop:disable Layout/LineLength
  let(:custom_fields) { [{ "id": 4418367585684, "value": 'on' }, { "id": 20697165967508, "value": 'on' }, { "id": 4418412738836, "value": 'General Services Administration' }, { "id": 4417546214292, "value": 'LGMIA999999' }, { "id": 4417547364628, "value": 'BillingPOC TestUser - test.user@gsa.gov - 555-555-1234' }, { "id": 4417948129556, "value": 'https://portal.int.identitysandbox.gov/service_providers/9999' }, { "id": 23180053076628, "value": 'urn:issuer:testing:gsa:test_application' }, { "id": 4417940288916, "value": 'https://fakeapplication.gov/logingov' }, { "id": 4417492827796, "value": 'Application Name - Testing Application' }, { "id": 5064895580308, "value": 'Application Description' }, { "id": 14323206118676, "value": 'General public' }, { "id": 4417514509076, "value": '100000' }, { "id": 14323273767572, "value": '1000' }, { "id": 14326923502100, "value": 'All Year Seasonality' }, { "id": 4417513940756, "value": '1200000' }, { "id": 4417494977300, "value": 'ial1' }, { "id": 4417512374548, "value": '2025-01-01' }, { "id": 4417948190868, "value": 'PM - test.user@gsa.gov - 555-555-1234' }, { "id": 4417940248340, "value": 'Techsupport - test.user@gsa.gov - 555-555-1234' }, { "id": 4975909708564, "value": 'Helpdesk Contact Info' }, { "id": 4417169610388, "value": 'new_integration' }] }
  # rubocop:enable Layout/LineLength

  describe 'ticket field functions' do
    context 'in prod_like_env' do
      before do
        allow(IdentityConfig.store).to receive_messages(prod_like_env: true)
      end

      it 'sets the request type to integration_change' do
        expect(
          zendesk_request.ticket_field_functions[4417169610388].call(sp),
        ).to eq('integration_change')
      end
    end

    context 'in sandbox env' do
      before do
        allow(IdentityConfig.store).to receive_messages(prod_like_env: false)
      end

      it 'sets the request type to new_integration' do
        expect(
          zendesk_request.ticket_field_functions[4417169610388].call(sp),
        ).to eq('new_integration')
      end
    end
  end

  describe 'initialize' do
    it 'initializes' do
      expect(zendesk_request.requestor).to eq(user)
      expect(zendesk_request.portal_url).to eq(portal_url)
      expect(zendesk_request.service_provider).to eq(sp)
    end
  end

  describe 'build zendesk request' do
    it 'builds the ticket request data' do
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
      expected_subject = "Deploy #{sp.friendly_name} to Production"
      expect(subject).to eq(expected_subject)
    end
  end

  describe 'ticket_body' do
    it 'generates the proper ticket body' do
      description = zendesk_request.ticket_body
      expected_body = "Please deploy #{sp.friendly_name} to the Login.gov Production Environment"
      expect(description).to eq(expected_body)
    end
  end

  describe 'ial_value' do
    it 'has an ial_value of 1' do
      sp.ial = 1
      sp.save
      ial = zendesk_request.ial_value
      expect(ial).to eq({ id: ZendeskRequest::ZENDESK_IAL_VALUE_ID, value: 'ial1' })

    end
    it 'has an ial_value of 2' do
      sp.ial = 2
      sp.save
      ial = zendesk_request.ial_value
      expect(ial).to eq({ id: ZendeskRequest::ZENDESK_IAL_VALUE_ID, value: 'idv' })
    end
  end

  describe 'create_ticket' do
    it 'gets the ticket id on success' do

      stubs.post('/api/v2/requests.json', custom_fields.to_json) do |env|
        [
          201,
          { 'Content-Type' => 'application/json' },
          # rubocop:disable Layout/LineLength
          '{"request":{"url":"https://logingov.zendesk.com/api/v2/requests/1.json","id":1,"status":"new","priority":null,"type":null,"subject":"Deploy to Production","description":"Please deployto the Login.gov Production Environment","organization_id":11664562433172,"via":{"channel":"api","source":{"from":{},"to":{},"rel":null}},"custom_fields":[{"id":4418367585684,"value":true},{"id":20697165967508,"value":true},{"id":4418412738836,"value":null},{"id":4417546214292,"value":"LGMIA999999"},{"id":4417547364628,"value":"BillingPOC TestUser - test.user@gsa.gov - 555-555-1234"},{"id":4417948129556,"value":"https://portal.int.identitysandbox.gov/service_providers/9999"},{"id":23180053076628,"value":"urn:issuer:testing;makingthisupasigo"},{"id":4417940288916,"value":"https://portal.int.gov/ApplicationURL"},{"id":4417492827796,"value":"Application Name - Testing Application"},{"id":5064895580308,"value":"Application Description"},{"id":14323206118676,"value":null},{"id":4417514509076,"value":"100000"},{"id":14323273767572,"value":"1000"},{"id":14326923502100,"value":"All Year Seasonality"},{"id":4417513940756,"value":"1200000"},{"id":4417494977300,"value":"ial1"},{"id":4417512374548,"value":"2025-06-01"},{"id":4417948190868,"value":"PM TestUser - test.user@gsa.gov - 555-555-1234"},{"id":4417940248340,"value":"Techsupport TestUser - test.user@gsa.gov - 555-555-1234"},{"id":14334218805396,"value":null},{"id":4975909708564,"value":"Helpdesk Contact Info"},{"id":4417940153620,"value":null},{"id":4417169610388,"value":"new_integration"}],"requester_id":10679225636756,"collaborator_ids":[],"email_cc_ids":[],"is_public":true,"due_at":null,"can_be_solved_by_me":false,"created_at":"2025-03-14T13:23:55Z","updated_at":"2025-03-14T13:23:55Z","recipient":null,"followup_source_id":null,"assignee_id":null,"ticket_form_id":5663417357332,"fields":[{"id":4418367585684,"value":true},{"id":20697165967508,"value":true},{"id":4418412738836,"value":null},{"id":4417546214292,"value":"LGABCFY210001-0001-0000"},{"id":4417547364628,"value":"BillingPOC TestUser - test.user@gsa.gov - 555-555-1234"},{"id":4417948129556,"value":"https://portal.int.identitysandbox.gov/service_providers/9999"},{"id":23180053076628,"value":"urn:issuer:testing;makingthisupasigo"},{"id":4417940288916,"value":"https://portal.int.gov/ApplicationURL"},{"id":4417492827796,"value":"Application Name - Testing Application"},{"id":5064895580308,"value":"Application Description"},{"id":14323206118676,"value":null},{"id":4417514509076,"value":"100000"},{"id":14323273767572,"value":"1000"},{"id":14326923502100,"value":"All Year Seasonality"},{"id":4417513940756,"value":"1200000"},{"id":4417494977300,"value":"ial1"},{"id":4417512374548,"value":"2025-06-01"},{"id":4417948190868,"value":"PM TestUser - test.user@gsa.gov - 555-555-1234"},{"id":4417940248340,"value":"Techsupport TestUser - test.user@gsa.gov - 555-555-1234"},{"id":14334218805396,"value":null},{"id":4975909708564,"value":"Helpdesk Contact Info"},{"id":4417940153620,"value":null},{"id":4417169610388,"value":"new_integration"}]}}',
          # rubocop:enable Layout/LineLength
        ]
      end

      zendesk_request.conn = conn
      expect(zendesk_request.create_ticket(custom_fields)).to eq({ success: true, ticket_id: 1 })
      stubs.verify_stubbed_calls
    end

    it 'generates errors on failure' do
      stubs.post('/api/v2/requests.json', custom_fields.to_json) do |env|
        [
          422,
          { 'Content-Type' => 'application/json' },
          # rubocop:disable Layout/LineLength
          '{"error":"RecordInvalid","description":"Record validation errors","details":{"base":[{"description":"Application URL: is invalid","error":"InvalidValue","field_key":4417940288916}, {"description":"Partner Portal Config URL: is invalid","error":"InvalidValue","field_key":4417948129556}]}}',
          # rubocop:enable Layout/LineLength
        ]
      end

      zendesk_request.conn = conn
      expect(zendesk_request.create_ticket(custom_fields)).to eq({ success: false,
errors: ['Application URL: is invalid', 'Partner Portal Config URL: is invalid'] })
      stubs.verify_stubbed_calls
    end
  end
end
