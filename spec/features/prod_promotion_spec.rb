require 'rails_helper'

feature 'requesting a promotion to production' do
  let(:partner_admin) { create(:team_membership, :partner_admin).user }
  let(:team) { partner_admin.teams.last }
  let(:sp) { create(:service_provider, :ready_to_activate, team: team, prod_config: true) }
  let(:expected_id) { rand(10..10000) }

  context 'as a partner looking at a service provider config' do
    before do
      login_as partner_admin
      visit service_provider_path(sp)
    end

    it 'allows requesting a zendesk ticket', :js do
      stub_request(:post, "#{ZendeskRequest::ZENDESK_BASE_URL}#{ZendeskRequest::ZENDESK_POST_PATH}")
        .with(
          body: expected_body_with_reasonable_data(partner_admin, sp),
        ).to_return(
          status: 201,
          body: %({"request":{"id":#{expected_id}}}),
        )
      click_on 'Submit a request'
      expect(page).to have_content('Please enter the information below')

      fill_in_reasonable_data
      click_on 'Submit Request'

      expect(page).to have_content(
        "Request submitted successfully. Ticket ##{expected_id} has been created on your behalf, " \
        "replies will be sent to #{partner_admin.email}",
      )
    end

    it 'handles a config failure', :js do
      stub_request(:post, "#{ZendeskRequest::ZENDESK_BASE_URL}#{ZendeskRequest::ZENDESK_POST_PATH}")
        .with(
          body: expected_body_with_reasonable_data(partner_admin, sp),
        ).to_return(
          status: 422,
          body: {
            'error' => 'RecordInvalid', 'description' => 'Record validation errors',
            'details' => { 'base' => [
              {
                'description' => 'Application URL: is invalid',
                'error' => 'InvalidValue',
                'field_key' => 4417940288916,
              },
            ] }
          }.to_json,
        )
      click_on 'Submit a request'
      expect(page).to have_content('Please enter the information below')

      fill_in_reasonable_data
      click_on 'Submit Request'

      expect(page).to have_content(
        'Please fix the following problems with your configuration before submitting a request.',
      )
      expect(page).to have_content('Application URL: is invalid. Please try again.')
    end

    it 'handles an unexpected failure', :js do
      stub_request(:post, "#{ZendeskRequest::ZENDESK_BASE_URL}#{ZendeskRequest::ZENDESK_POST_PATH}")
        .with(
          body: expected_body_with_reasonable_data(partner_admin, sp),
        ).to_return(
          status: 500,
          body: '{"error":"something weird happened"}',
        )
      click_on 'Submit a request'
      expect(page).to have_content('Please enter the information below')

      fill_in_reasonable_data
      click_on 'Submit Request'

      expect(page).to have_content('An unknown error occurred.')
      expect(page).to have_content('You can create a request manually through')
      expect(page).to have_link('this contact form', href: 'https://partners.login.gov/hc/en-us/requests/new')
    end
  end

  def fill_in_reasonable_data # rubocop:disable Metrics/MethodLength
    fill_in 'Application URL', with: 'https://localhost'
    select 'General public', from: 'Application Audience User Base'
    fill_in 'Billing POCs', with: 'Bill Billings — 555 555 1234'
    fill_in 'Estimated Annual Registrations', with: '1234'
    fill_in 'Estimated Authentications', with: '12345'
    fill_in 'Help Desk Contact Information', with: '555 GOV HELP'
    fill_in 'IAA Number', with: '1234LGTM-5678'
    fill_in 'Desired Launch Date', with: '01/01/2027'
    fill_in 'Monthly Active Users', with: '2345'
    fill_in 'Program Management POCs', with: 'Pam Manager - 555 555 5432'
    fill_in 'Seasonality of Application Usage', with: 'yes'
    fill_in 'Technical Support POCs', with: 'Tracy Suber - 555 555 9876'
  end

  def expected_body_with_reasonable_data(user, sp)
    { request: {
      requester: {
        name: "#{user.first_name} #{user.last_name}",
        email: user.email,
      },
      subject: "Deploy #{sp.friendly_name} to Production",
      comment: {
        body: "Please deploy #{sp.friendly_name} to the Login.gov Production Environment",
      }, ticket_form_id: 5663417357332, custom_fields:
            [{ id: 4418412738836, value: sp.agency.name.parameterize.underscore },
             { id: 4417492827796, value: sp.app_name },
             { id: 5064895580308, value: sp.description },
             { id: 23180053076628, value: sp.issuer },
             { id: 20697165967508, value: false }, { id: 4417169610388, value: 'new_integration' },
             { id: 4418367585684, value: 'on' }, { id: 4417940288916, value: 'https://localhost' },
             { id: 14323206118676, value: 'general_public' },
             { id: 4417547364628, value: 'Bill Billings — 555 555 1234' },
             { id: 4417514509076, value: '1234' }, { id: 4417513940756, value: '12345' },
             { id: 4975909708564, value: '555 GOV HELP' },
             { id: 4417546214292, value: '1234LGTM-5678' },
             { id: 4417512374548, value: '2027-01-01' }, { id: 14323273767572, value: '2345' },
             { id: 4417948190868, value: 'Pam Manager - 555 555 5432' },
             { id: 14326923502100, value: 'yes' },
             { id: 4417940248340, value: 'Tracy Suber - 555 555 9876' },
             { id: 4417948129556, value: "http://127.0.0.1/service_providers/#{sp.id}" },
             { id: 4417494977300, value: sp.ial == 1 ? 'ial1' : 'idv' }]
    } }
  end
end
