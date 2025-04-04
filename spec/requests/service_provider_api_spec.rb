require 'rails_helper'

describe 'Service Provider API' do
  it 'returns JSON' do
    app = create(:service_provider)
    get api_service_providers_path
    json = response.parsed_body
    expect(response).to have_http_status(:ok)
    expect(json[0]['issuer']).to eq(app.issuer)
  end
end
