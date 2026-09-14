require 'rails_helper'

RSpec.describe SalesforceController do
  let(:logingov_admin) { create(:user, :logingov_admin) }

  before do
    sign_in logingov_admin
  end

  context 'in prod_like_env with salesforce enabled' do
    before do
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
      allow(IdentityConfig.store).to receive(:salesforce_api_enabled).and_return(true)
    end

    describe 'GET #index' do
      it 'fetches a token and renders successfully' do
        expect_any_instance_of(Salesforce).to receive(:token).and_return('mock_access_token')

        get :index

        expect(response).to be_successful
        expect(assigns(:token)).to eq('mock_access_token')
        expect(assigns(:connection_error)).to be_nil
      end

      it 'assigns a connection error when the token fetch fails' do
        allow_any_instance_of(Salesforce).to receive(:token).and_raise('boom')

        get :index

        expect(response).to be_successful
        expect(assigns(:connection_error)).to eq('boom')
      end

      context 'with a team_id param' do
        let(:team) { create(:team) }

        before do
          create(:service_provider, team: team, uuid: 'sp-uuid-1')
          allow_any_instance_of(Salesforce).to receive(:token).and_return('mock_access_token')
        end

        it 'queries Salesforce using the team service provider uuids' do
          records = [{ 'Name' => 'LDGAC-1' }]
          expect_any_instance_of(Salesforce).to receive(:application_contacts_for_team_uuids)
            .with(['sp-uuid-1']).and_return(records)

          get :index, params: { team_id: team.id }

          expect(response).to be_successful
          expect(assigns(:team)).to eq(team)
          expect(assigns(:records)).to eq(records)
        end
      end
    end
  end

  context 'in prod_like_env with salesforce disabled' do
    before do
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
      allow(IdentityConfig.store).to receive(:salesforce_api_enabled).and_return(false)
    end

    describe 'GET #index' do
      it 'is unauthorized' do
        get :index

        expect(response).to be_unauthorized
      end
    end
  end

  context 'in non prod_like_env' do
    before do
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return(false)
      allow(IdentityConfig.store).to receive(:salesforce_api_enabled).and_return(true)
    end

    describe 'GET #index' do
      it 'is unauthorized' do
        get :index

        expect(response).to be_unauthorized
      end
    end
  end
end
