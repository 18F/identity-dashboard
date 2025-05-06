require 'rails_helper'

describe Api::ServiceProvidersController do
  def response_from_json
    JSON.parse(response.body, symbolize_names: true)
  end

  let(:user) { create(:user, :logingov_admin) }
  let(:token) do
    token = AuthToken.new_for_user(user)
    token.save!
    token.ephemeral_token
  end

  def add_token_to_headers(controller, user, token)
    auth_header_value = ActionController::HttpAuthentication::Token.encode_credentials(
      token, email: user.email
    )
    request.headers['HTTP_AUTHORIZATION'] = auth_header_value
  end

  describe '#index' do
    before { add_token_to_headers(controller, user, token) }

    it 'returns active, approved SPs' do
      sp = create(:service_provider, :with_team, active: true, approved: true)
      serialized_sp = ServiceProviderSerializer.new(sp).to_h

      get :index

      expect(response_from_json).to include serialized_sp.deep_symbolize_keys
    end

    xit 'does not return un-approved SPs' do
      sp = create(:service_provider, :with_team, active: true, approved: false)
      serialized_sp = ServiceProviderSerializer.new(sp).to_h

      get :index

      expect(response_from_json).to_not include serialized_sp
    end

    it 'includes non-active SPs' do
      sp = create(:service_provider, :with_team, active: false, approved: true)
      serialized_sp = ServiceProviderSerializer.new(sp).to_h

      get :index
      expect(response_from_json).to include serialized_sp.deep_symbolize_keys
    end

    it 'does not return the protocol attribute' do
      sp = create(:service_provider, :with_team, active: true, approved: true)

      get :index
      expect(response_from_json.first.keys).to_not include :protocol
    end
  end

  describe '#show' do
    let(:sp) { create(:service_provider, :with_team) }

    before { get :show, params: { id: sp.id } }

    it 'returns the service provider whose params are passed in' do
      serialized = ServiceProviderSerializer.new(sp, action: :show).to_h

      expect(response_from_json).to eq(serialized.deep_symbolize_keys)
    end

    it 'includes the protocol attribute' do
      expect(response_from_json.keys).to include :protocol
    end
  end
end
