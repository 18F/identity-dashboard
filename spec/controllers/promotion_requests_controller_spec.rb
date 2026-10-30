require 'rails_helper'

RSpec.describe PromotionRequestsController do
  let(:user) { create(:team_membership, :partner_admin).user }
  let(:sp) { create(:service_provider, :ready_to_activate, team: user.teams.last) }

  context 'when logged in as a user who does not have permission' do
    before do
      sign_in create(:user)
    end

    it 'it does not have permission' do
      post :create, params: { service_provider: { id: sp.id } }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when logged in as a partner team admin' do
    let(:expected_ticket_id) { rand(1..10000) }

    before do
      sign_in user
    end

    it 'can redirect with a success message' do
      stub_request(:post, 'https://logingov.zendesk.com/api/v2/requests.json')
        .to_return(status: 201, body: %({"request":{"id":#{expected_ticket_id}}}), headers: {})

      post :create, params: { service_provider: { id: sp.id } }

      expect(response).to have_http_status(:found)
      expect(redirect_to_url).to eq(service_provider_url(sp))

      expect(flash[:success]).to include("Ticket ##{expected_ticket_id}")
      expect(flash[:success]).to include(
        "has been created on your behalf, replies will be sent to #{user.email}.",
      )
    end

    context 'with a mocked ZendeskRequest' do
      let(:test_params) do
        { service_provider: { 'id' => sp.id.to_s, '4418412738836' => 'some agency' } }
      end
      let(:request_mock) { instance_double(ZendeskRequest) }

      before do
        expect(ZendeskRequest).to receive(:new)
          .with(user, service_provider_url(sp), sp)
          .and_return(request_mock)
        expect(request_mock).to receive(:add_fields_from_params) do |param_args|
          expect(param_args[:service_provider].to_h).to eq(test_params[:service_provider])
        end
      end

      it 'can redirect with a success response' do
        expect(request_mock).to receive(:create_ticket)
          .with(no_args)
          .and_return({ success: true, ticket_id: expected_ticket_id })

        post :create, params: test_params

        expect(response).to have_http_status(:found)
        expect(redirect_to_url).to eq(service_provider_url(sp))

        expect(flash[:success]).to include("Ticket ##{expected_ticket_id}")
        expect(flash[:success]).to include(
          "has been created on your behalf, replies will be sent to #{user.email}.",
        )
      end

      it 'can redirect with a failure response' do
        expect(request_mock).to receive(:create_ticket)
          .with(no_args)
          .and_return({
            success: false,
            errors: ZendeskErrors.new([{ 'description' => 'Application URL: is invalid' }]),
          })

        post :create, params: test_params

        expect(response).to have_http_status(:found)
        expect(redirect_to_url).to eq(service_provider_url(sp))

        expect(flash[:error]).to include(
          'Please fix the following problems with your configuration before submitting a request.',
        )
        expect(flash[:error]).to include(
          'Application URL: is invalid. Please try again.',
        )
      end
    end
  end
end
