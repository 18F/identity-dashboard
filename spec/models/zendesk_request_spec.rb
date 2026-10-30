require 'rails_helper'
require 'nokogiri'

describe ZendeskRequest do
  let(:user) { build(:user) }
  let(:sp) { create(:service_provider, :ready_to_activate_ial_1) }
  let(:portal_url) { "https://portal.invalid.identitysandbox.gov/service_providers/#{rand(10..1000)}" }
  let(:zendesk_request) { ZendeskRequest.new(user, portal_url, sp) }
  let(:faraday_stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:stubbed_connection) do
    Faraday.new(url: ZendeskRequest::ZENDESK_BASE_URL) { |b| b.adapter(:test, faraday_stubs) }
  end
  let(:sample_params) do
    {
      '4417940288916': 'https://myapp.gov',
      '14323206118676': 'state_or_local_employee',
      '4417547364628': 'BillingPOC TestUser - test.user@gsa.gov - 555-555-1234',
      '4417514509076': 100000,
      '4417513940756': 1200000,
      '4975909708564': 'Helpdesk Contact Info',
      '4417546214292': 'LGMIA999999',
      '4417512374548': '2025-01-01',
      '14323273767572': 1000,
      '4417948190868': 'PM - test.user@gsa.gov - 555-555-1234',
      '14326923502100': 'All Year Seasonality',
      '4417940248340': 'Techsupport - test.user@gsa.gov - 555-555-1234',
    }
  end

  let(:custom_fields) do
    [
      { id: 4418412738836, value: sp.agency.name.parameterize.underscore },
      { id: 4417492827796, value: sp.app_name },
      { id: 5064895580308, value: sp.description },
      { id: 23180053076628, value: sp.issuer },
      { id: 20697165967508, value: sp.logo.present? },
      { id: 4417169610388, value: 'new_integration' },
      { id: 4418367585684, value: 'on' },
      { id: 4417494977300, value: 'ial1' },
      *(sample_params.map { |key, value| { id: key.to_s.to_i, value: } }),
      { id: 4417948129556, value: portal_url },
    ]
  end

  let(:expected_request) do
    { request: {
      requester: { name: "#{user.first_name} #{user.last_name}", email: user.email },
      subject: "Deploy #{sp.friendly_name} to Production",
      comment: { body: "Please deploy #{sp.friendly_name} to the Login.gov Production Environment" },
      ticket_form_id: 5663417357332,
      custom_fields:,
    } }
  end

  describe 'ticket field functions' do
    context 'in prod_like_env' do
      before do
        allow(IdentityConfig.store).to receive_messages(prod_like_env: true)
      end

      it 'sets the request type to integration_change' do
        expect(
          described_class::ZENDESK_TICKET_FIELD_FUNCTIONS[4417169610388].call(sp),
        ).to eq('integration_change')
      end
    end

    context 'in sandbox env' do
      before do
        allow(IdentityConfig.store).to receive_messages(prod_like_env: false)
      end

      it 'sets the request type to new_integration' do
        expect(
          described_class::ZENDESK_TICKET_FIELD_FUNCTIONS[4417169610388].call(sp),
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

  describe 'fields' do
    it 'generates the proper ticket subject line' do
      subject = zendesk_request.fields[:request][:subject]
      expected_subject = "Deploy #{sp.friendly_name} to Production"
      expect(subject).to eq(expected_subject)
    end

    it 'generates the proper ticket body' do
      description = zendesk_request.fields[:request][:comment][:body]
      expected_body = "Please deploy #{sp.friendly_name} to the Login.gov Production Environment"
      expect(description).to eq(expected_body)
    end
  end

  describe 'add_fields_from_config' do
    it 'can set an ial_value of 1' do
      sp.ial = 1
      zendesk_request.add_fields_from_config(sp)
      expect(zendesk_request.custom_fields[ZendeskRequest::ZENDESK_IAL_VALUE_ID]).to eq('ial1')
      expect(zendesk_request.fields[:request][:custom_fields]).to include(
        { id: ZendeskRequest::ZENDESK_IAL_VALUE_ID, value: 'ial1' },
      )
    end

    it 'can set an ial_value of 2' do
      sp.ial = 2
      zendesk_request.add_fields_from_config(sp)
      expect(zendesk_request.custom_fields[ZendeskRequest::ZENDESK_IAL_VALUE_ID]).to eq('idv')
      expect(zendesk_request.fields[:request][:custom_fields]).to include(
        { id: ZendeskRequest::ZENDESK_IAL_VALUE_ID, value: 'idv' },
      )
    end
  end

  describe 'create_ticket' do
    before do
      allow(Faraday).to receive(:new).with(
        { headers: { 'Content-Type' => 'application/json' }, url: 'https://logingov.zendesk.com' },
      ).and_return(stubbed_connection)
    end

    it 'gets the ticket id on success' do
      faraday_stubs.post('/api/v2/requests.json', expected_request.to_json) do |_env|
        [
          201,
          { 'Content-Type' => 'application/json' },
          # rubocop:disable Layout/LineLength
          '{"request":{"url":"https://logingov.zendesk.com/api/v2/requests/1.json","id":1,"status":"new","priority":null,"type":null,"subject":"Deploy to Production","description":"Please deployto the Login.gov Production Environment","organization_id":11664562433172,"via":{"channel":"api","source":{"from":{},"to":{},"rel":null}},"custom_fields":[{"id":4418367585684,"value":true},{"id":20697165967508,"value":true},{"id":4418412738836,"value":null},{"id":4417546214292,"value":"LGMIA999999"},{"id":4417547364628,"value":"BillingPOC TestUser - test.user@gsa.gov - 555-555-1234"},{"id":4417948129556,"value":"https://portal.int.identitysandbox.gov/service_providers/9999"},{"id":23180053076628,"value":"urn:issuer:testing;makingthisupasigo"},{"id":4417940288916,"value":"https://portal.int.gov/ApplicationURL"},{"id":4417492827796,"value":"Application Name - Testing Application"},{"id":5064895580308,"value":"Application Description"},{"id":14323206118676,"value":null},{"id":4417514509076,"value":"100000"},{"id":14323273767572,"value":"1000"},{"id":14326923502100,"value":"All Year Seasonality"},{"id":4417513940756,"value":"1200000"},{"id":4417494977300,"value":"ial1"},{"id":4417512374548,"value":"2025-06-01"},{"id":4417948190868,"value":"PM TestUser - test.user@gsa.gov - 555-555-1234"},{"id":4417940248340,"value":"Techsupport TestUser - test.user@gsa.gov - 555-555-1234"},{"id":14334218805396,"value":null},{"id":4975909708564,"value":"Helpdesk Contact Info"},{"id":4417940153620,"value":null},{"id":4417169610388,"value":"new_integration"}],"requester_id":10679225636756,"collaborator_ids":[],"email_cc_ids":[],"is_public":true,"due_at":null,"can_be_solved_by_me":false,"created_at":"2025-03-14T13:23:55Z","updated_at":"2025-03-14T13:23:55Z","recipient":null,"followup_source_id":null,"assignee_id":null,"ticket_form_id":5663417357332,"fields":[{"id":4418367585684,"value":true},{"id":20697165967508,"value":true},{"id":4418412738836,"value":null},{"id":4417546214292,"value":"LGABCFY210001-0001-0000"},{"id":4417547364628,"value":"BillingPOC TestUser - test.user@gsa.gov - 555-555-1234"},{"id":4417948129556,"value":"https://portal.int.identitysandbox.gov/service_providers/9999"},{"id":23180053076628,"value":"urn:issuer:testing;makingthisupasigo"},{"id":4417940288916,"value":"https://portal.int.gov/ApplicationURL"},{"id":4417492827796,"value":"Application Name - Testing Application"},{"id":5064895580308,"value":"Application Description"},{"id":14323206118676,"value":null},{"id":4417514509076,"value":"100000"},{"id":14323273767572,"value":"1000"},{"id":14326923502100,"value":"All Year Seasonality"},{"id":4417513940756,"value":"1200000"},{"id":4417494977300,"value":"ial1"},{"id":4417512374548,"value":"2025-06-01"},{"id":4417948190868,"value":"PM TestUser - test.user@gsa.gov - 555-555-1234"},{"id":4417940248340,"value":"Techsupport TestUser - test.user@gsa.gov - 555-555-1234"},{"id":14334218805396,"value":null},{"id":4975909708564,"value":"Helpdesk Contact Info"},{"id":4417940153620,"value":null},{"id":4417169610388,"value":"new_integration"}]}}',
          # rubocop:enable Layout/LineLength
        ]
      end

      zendesk_request.add_fields_from_params({ service_provider: sample_params })
      expect(zendesk_request.create_ticket).to eq({ success: true, ticket_id: 1 })
      faraday_stubs.verify_stubbed_calls
    end

    it 'returns unrecoverable error list when an unrecoverble error happens' do
      faraday_stubs.post('/api/v2/requests.json', expected_request.to_json) do |_env|
        [
          422,
          { 'Content-Type' => 'application/json' },
          # rubocop:disable Layout/LineLength
          '{"error":"RecordInvalid","description":"Record validation errors","details":{"base":[{"description":"Application URL: is invalid","error":"InvalidValue","field_key":4417940288916}, {"description":"Partner Portal Configuration URL: is invalid","error":"InvalidValue","field_key":4417948129556}]}}',
          # rubocop:enable Layout/LineLength
        ]
      end

      zendesk_request.add_fields_from_params({ service_provider: sample_params })
      result = zendesk_request.create_ticket
      expect(result[:success]).to be_falsey
      expect(result[:errors].messages).to eq(['Partner Portal Configuration URL: is invalid'])
      faraday_stubs.verify_stubbed_calls
    end

    it 'returns a full error list when errors are all recoverable' do
      faraday_stubs.post('/api/v2/requests.json', expected_request.to_json) do |_env|
        [
          422,
          { 'Content-Type' => 'application/json' },
          # rubocop:disable Layout/LineLength
          '{"error":"RecordInvalid","description":"Record validation errors","details":{"base":[{"description":"Application URL: is invalid","error":"InvalidValue","field_key":4417940288916},{"description":"Application Description: is invalid","error":"InvalidValue","field_key":5064895580308}]}}',
          # rubocop:enable Layout/LineLength
        ]
      end

      zendesk_request.add_fields_from_params({ service_provider: sample_params })
      result = zendesk_request.create_ticket
      expect(result[:success]).to be_falsey
      expect(result[:errors].messages).to eq(['Application URL: is invalid',
                                              'Application Description: is invalid'])
      faraday_stubs.verify_stubbed_calls
    end

    it 'handles a rate limit error as unrecoverable' do
      faraday_stubs.post('/api/v2/requests.json', expected_request.to_json) do |_env|
        [
          429,
          { 'Content-Type' => 'application/json' },
          '{"error":"TooManyRequests","description":"Rate limit exceeded"}',
        ]
      end
      zendesk_request.add_fields_from_params({ service_provider: sample_params })
      result = zendesk_request.create_ticket
      expect(result[:success]).to be_falsey
      expect(result[:errors].messages).to eq(['Rate limit exceeded'])
    end
  end
end
