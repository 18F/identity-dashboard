require 'rails_helper'

describe 'Service Provider API' do
  it 'returns JSON' do
    app = create(:service_provider)
    get api_service_providers_path
    json = JSON.parse(response.body)
    expect(response).to be_success
    expect(json[0]['issuer']).to eq(app.issuer)
  end
end
