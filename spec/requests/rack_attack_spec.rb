require 'rails_helper'

RSpec.describe 'throttling requests' do
  before do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.cache.store.clear
  end

  context 'with an invalid token' do
    let(:auth_header) do
      user = build(:user)
      invalid_credentials = ActionController::HttpAuthentication::Token.encode_credentials(
        SecureRandom.base64(54), email: user.email
      )
      { 'HTTP_AUTHORIZATION' => invalid_credentials }
    end

    it 'allows an initial access' do
      get '/', headers: auth_header
      expect(response).to have_http_status(:ok)
      expect(request.env['rack.attack.match_type']).to be_nil
    end

    it 'forbids with frequent access' do
      freeze_time do
        6.times do
          get api_service_providers_path, headers: auth_header
        end
        expect(response).to_not have_http_status(:ok)
        expect(request.env['rack.attack.match_type']).to eq(:blocklist)
      end
    end
  end
end
