require 'rails_helper'

describe 'Service Provider API' do
  before do
    Rack::Attack.reset!
  end

  context 'with API token required enabled' do
    before do
      allow(IdentityConfig.store).to receive(:api_token_required_enabled).and_return(true)
    end

    context 'without API token' do
      it 'fails without authorization header' do
        get api_service_providers_path

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
        config = create(:service_provider)
        get api_service_providers_path, headers: auth_header
        json = response.parsed_body
        expect(response).to have_http_status(:ok)
        expect(json[0]['issuer']).to eq(config.issuer)
      end
    end
  end

  context 'with API token required disabled' do
    before do
      allow(IdentityConfig.store).to receive(:api_token_required_enabled).and_return(false)
    end

    context 'without API token' do
      it 'returns JSON' do
        config = create(:service_provider)
        get api_service_providers_path
        json = response.parsed_body
        expect(response).to have_http_status(:ok)
        expect(json[0]['issuer']).to eq(config.issuer)
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
        config = create(:service_provider)
        get api_service_providers_path, headers: auth_header
        json = response.parsed_body
        expect(response).to have_http_status(:ok)
        expect(json[0]['issuer']).to eq(config.issuer)
      end
    end
  end
end
