require 'rails_helper'

describe 'Service Provider API' do
  before do
    Rack::Attack.reset!
  end

  context 'without API token' do
    it 'fails without authorization header' do
      app = create(:service_provider)
      get api_service_providers_path
      json = response.parsed_body
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'with API token' do
    let(:user) { create(:user, :logingov_admin) }
    let(:token) do
      token = AuthToken.new_for_user(user)
      token.save!
      token.ephemeral_token
    end

    let(:auth_header) do
      { 'Authorization' => "Token #{token}, email=#{user.email}" }
    end

    it 'returns JSON' do
      app = create(:service_provider)
      get api_service_providers_path, headers: auth_header
      json = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(json[0]['issuer']).to eq(app.issuer)
    end
  end
end
