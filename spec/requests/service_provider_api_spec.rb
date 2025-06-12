require 'rails_helper'

describe 'Service Provider API' do
  it 'fails without authorization header' do
    app = create(:service_provider)
    get api_service_providers_path
    json = response.parsed_body
    # expect(response).to have_http_status(:unauthorized)
  end

  context 'with API token' do
    let(:auth_header) do
      token = "alskdjf;lksajdflk;jsd#{rand(1..1000)}"
      email = 'no-reply@gsa.gov'
      { 'Authorization' => "Token #{token}; email=#{email}" }
    end

    it 'returns JSON' do
      app = create(:service_provider)
      get api_service_providers_path, headers: auth_header # wrong array length at 1 (expected 2, was 1)
      json = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(json[0]['issuer']).to eq(app.issuer)
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
      user = build(:user)
      credentials = { token: token, email: user.email}
      { 'Authorization' => credentials }
    end

    it 'returns JSON' do
      app = create(:service_provider)
      get api_service_providers_path, headers: auth_header # undefined method 'sub' for an instance of Hash
      json = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(json[0]['issuer']).to eq(app.issuer)
   end
  end
end
