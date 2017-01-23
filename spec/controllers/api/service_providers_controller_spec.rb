require 'rails_helper'

describe Api::ServiceProvidersController do
  def response_from_json
    JSON.parse(response.body, symbolize_names: true)
  end

  describe '#index' do
    it 'returns active, approved SPs' do
      sp = create(:service_provider, active: true, approved: true)
      serialized_sp = ServiceProviderSerializer.new(sp).to_h

      get :index

      expect(response_from_json).to include serialized_sp
    end

    pending 'does not return un-approved SPs' do
      sp = create(:service_provider, active: true, approved: false)
      serialized_sp = ServiceProviderSerializer.new(sp).to_h

      get :index

      expect(response_from_json).to_not include serialized_sp
    end

    it 'does not return non-active SPs' do
      sp = create(:service_provider, active: false, approved: true)
      serialized_sp = ServiceProviderSerializer.new(sp).to_h

      get :index

      expect(response_from_json).to_not include serialized_sp
    end
  end

  describe '#update' do
    context 'no user' do
      it 'requires authentication' do
        post :update

        expect(response).to redirect_to new_user_session_path
      end
    end

    context 'with user' do
      before do
        user = create(:user)
        sign_in(user)
      end

      it 'creates delayed job' do
        expect(Delayed::Job.count).to eq 0

        post :update

        expect(response).to redirect_to users_service_providers_path
        expect(Delayed::Job.count).to eq 1
      end
    end
  end
end
