require 'rails_helper'

describe ExtractsController do
  include Devise::Test::ControllerHelpers

  let(:partner) { create(:user) }
  let(:admin) { create(:user, :logingov_admin) }
  let(:sp1) { create(:service_provider, :ready_to_activate ) }
  let(:params1) do
    { extract: {
      ticket: '1', search_by: 'teams', criteria_list: sp1.group_id
    } }
  end

  describe 'a non-admin user' do
    before do
      sign_in partner
    end

    context '#index' do
      it 'does not have GET access' do
        get :index
        expect(response).to be_unauthorized
      end
    end

    context '#create' do
      it 'does not have POST access' do
        post :create, params: params1
        expect(response).to be_unauthorized
      end
    end
  end

  describe 'a logingov_admin user' do
    before do
      sign_in admin
    end

    context '#index' do
      it 'has GET access' do
        get :index
        expect(response).to be_ok
      end
    end

    context '#create' do
      it 'is rejected without required params' do
        post :create, params: { extract: {
          search_by: '',
        } }

        expect(assigns[:extract].errors).to include(
          :ticket,
          :search_by,
          :criteria_file,
          :criteria_list,
        )
      end
    end
  end
end
