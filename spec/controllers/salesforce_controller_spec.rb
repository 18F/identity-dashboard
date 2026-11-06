require 'rails_helper'

RSpec.describe SalesforceController do
  let(:logingov_admin) { create(:user, :logingov_admin) }

  before do
    sign_in logingov_admin
  end

  context 'in prod_like_env' do
    before { allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true) }

    describe 'GET #index' do
      it 'fetches a token and renders successfully' do
        expect_any_instance_of(SalesforceService).to receive(:token).and_return('mock_access_token')

        get :index

        expect(response).to be_successful
        expect(assigns(:token)).to eq('mock_access_token')
        expect(assigns(:connection_error)).to be_nil
      end

      it 'assigns a connection error when the token fetch fails' do
        allow_any_instance_of(SalesforceService).to receive(:token).and_raise('boom')

        get :index

        expect(response).to be_successful
        expect(assigns(:connection_error)).to eq('boom')
      end
    end
  end

  context 'in non prod_like_env' do
    before { allow(IdentityConfig.store).to receive(:prod_like_env).and_return(false) }

    describe 'GET #index' do
      it 'is unauthorized' do
        get :index

        expect(response).to be_unauthorized
      end
    end
  end
end
