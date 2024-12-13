require 'rails_helper'

describe 'Service Provider API' do
  it 'returns JSON' do
    app = create(:service_provider)
    get api_service_providers_path
    json = JSON.parse(response.body)
    expect(response.status).to eq(200)
    expect(json.last['issuer']).to eq(app.issuer)
  end
end
