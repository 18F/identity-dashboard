require 'rails_helper'

RSpec.describe PromotionRequestsController do
  let(:user) { create(:team_membership, :partner_admin).user }
  let(:sp) { create(:service_provider, :ready_to_activate, team: user.teams.last) }
  let(:faraday_stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:stubbed_connection) do
    Faraday.new(url: ZendeskRequest::ZENDESK_BASE_URL) { |b| b.adapter(:test, faraday_stubs) }
  end
  let(:custom_fields) do
    [{ id: 4418412738836, value: sp.agency.name.parameterize.underscore },
     { id: 4417492827796, value: sp.app_name },
     { id: 5064895580308, value: sp.description },
     { id: 23180053076628, value: sp.issuer },
     { id: 20697165967508, value: false }, { id: 4417169610388, value: 'new_integration' },
     { id: 4418367585684, value: 'on' },
     { id: 4417494977300, value: sp.ial == 1 ? 'ial1' : 'idv' },
     { id: 4417940288916, value: nil },
     { id: 14323206118676, value: nil },
     { id: 4417547364628, value: nil },
     { id: 4417514509076, value: nil }, { id: 4417513940756, value: nil },
     { id: 4975909708564, value: nil },
     { id: 4417546214292, value: nil },
     { id: 4417512374548, value: nil }, { id: 14323273767572, value: nil },
     { id: 4417948190868, value: nil },
     { id: 14326923502100, value: nil },
     { id: 4417940248340, value: nil },
     { id: 4417948129556, value: service_provider_url(sp) }]
  end
  let(:expected_request) do
    {
      request: {
        requester: {
          name: "#{user.first_name} #{user.last_name}",
          email: user.email,
        },
        subject: "Deploy #{sp.friendly_name} to Production",
        comment: {
          body: "Please deploy #{sp.friendly_name} to the Login.gov Production Environment",
        },
        ticket_form_id: 5663417357332,
        custom_fields: custom_fields,
      },
    }
  end

  before do
    allow(Faraday).to receive(:new).with(
      { headers: { 'Content-Type' => 'application/json' }, url: 'https://logingov.zendesk.com' },
    ).and_return(stubbed_connection)
  end

  context 'when logged in as a partner admin' do
    before do
      sign_in user
    end

    it 'makes a request to Zendesk' do
      faraday_stubs.post('/api/v2/requests.json', expected_request.to_json) do |_env|
        [
          201,
          { 'Content-Type' => 'application/json' },
          # rubocop:disable Layout/LineLength
          '{"request":{"url":"https://logingov.zendesk.com/api/v2/requests/1.json","id":1,"status":"new","priority":null,"type":null,"subject":"Deploy to Production","description":"Please deployto the Login.gov Production Environment","organization_id":11664562433172,"via":{"channel":"api","source":{"from":{},"to":{},"rel":null}},"custom_fields":[{"id":4418367585684,"value":true},{"id":20697165967508,"value":true},{"id":4418412738836,"value":null},{"id":4417546214292,"value":"LGMIA999999"},{"id":4417547364628,"value":"BillingPOC TestUser - test.user@gsa.gov - 555-555-1234"},{"id":4417948129556,"value":"https://portal.int.identitysandbox.gov/service_providers/9999"},{"id":23180053076628,"value":"urn:issuer:testing;makingthisupasigo"},{"id":4417940288916,"value":"https://portal.int.gov/ApplicationURL"},{"id":4417492827796,"value":"Application Name - Testing Application"},{"id":5064895580308,"value":"Application Description"},{"id":14323206118676,"value":null},{"id":4417514509076,"value":"100000"},{"id":14323273767572,"value":"1000"},{"id":14326923502100,"value":"All Year Seasonality"},{"id":4417513940756,"value":"1200000"},{"id":4417494977300,"value":"ial1"},{"id":4417512374548,"value":"2025-06-01"},{"id":4417948190868,"value":"PM TestUser - test.user@gsa.gov - 555-555-1234"},{"id":4417940248340,"value":"Techsupport TestUser - test.user@gsa.gov - 555-555-1234"},{"id":14334218805396,"value":null},{"id":4975909708564,"value":"Helpdesk Contact Info"},{"id":4417940153620,"value":null},{"id":4417169610388,"value":"new_integration"}],"requester_id":10679225636756,"collaborator_ids":[],"email_cc_ids":[],"is_public":true,"due_at":null,"can_be_solved_by_me":false,"created_at":"2025-03-14T13:23:55Z","updated_at":"2025-03-14T13:23:55Z","recipient":null,"followup_source_id":null,"assignee_id":null,"ticket_form_id":5663417357332,"fields":[{"id":4418367585684,"value":true},{"id":20697165967508,"value":true},{"id":4418412738836,"value":null},{"id":4417546214292,"value":"LGABCFY210001-0001-0000"},{"id":4417547364628,"value":"BillingPOC TestUser - test.user@gsa.gov - 555-555-1234"},{"id":4417948129556,"value":"https://portal.int.identitysandbox.gov/service_providers/9999"},{"id":23180053076628,"value":"urn:issuer:testing;makingthisupasigo"},{"id":4417940288916,"value":"https://portal.int.gov/ApplicationURL"},{"id":4417492827796,"value":"Application Name - Testing Application"},{"id":5064895580308,"value":"Application Description"},{"id":14323206118676,"value":null},{"id":4417514509076,"value":"100000"},{"id":14323273767572,"value":"1000"},{"id":14326923502100,"value":"All Year Seasonality"},{"id":4417513940756,"value":"1200000"},{"id":4417494977300,"value":"ial1"},{"id":4417512374548,"value":"2025-06-01"},{"id":4417948190868,"value":"PM TestUser - test.user@gsa.gov - 555-555-1234"},{"id":4417940248340,"value":"Techsupport TestUser - test.user@gsa.gov - 555-555-1234"},{"id":14334218805396,"value":null},{"id":4975909708564,"value":"Helpdesk Contact Info"},{"id":4417940153620,"value":null},{"id":4417169610388,"value":"new_integration"}]}}',
          # rubocop:enable Layout/LineLength
        ]
      end
      post :create, params: { service_provider: { id: sp.id } }
      faraday_stubs.verify_stubbed_calls
    end
  end
end
