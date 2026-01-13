require 'rails_helper'

RSpec.describe 'limiting suspicious requests' do
  let(:logger) { instance_double(ActiveSupport::Logger) }

  before do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.cache.store.clear
    allow(logger).to receive(:formatter=)
    allow(logger).to receive(:info)
    allow(ActiveSupport::Logger).to receive(:new).and_return(logger)
  end

  context 'with an invalid token' do
    let(:test_user) { build(:user) }
    let(:auth_header) do
      invalid_credentials = ActionController::HttpAuthentication::Token.encode_credentials(
        SecureRandom.base64(54), email: test_user.email
      )
      { 'HTTP_AUTHORIZATION' => invalid_credentials }
    end

    it 'allows an initial access' do
      get '/', headers: auth_header
      expect(response).to have_http_status(:ok)
      expect(request.env['rack.attack.match_type']).to be_nil
    end

    context 'with frequent auth attempts' do
      before do
        freeze_time do
          6.times do
            post '/auth/logindotgov', params: { email: 'some-fake-email' }
          end
        end
      end

      it 'blocks access' do
        expect(response).to_not have_http_status(:ok)
        expect(request.env['rack.attack.match_type']).to eq(:throttle)
      end

      it 'logs the throttle action' do
        expect(logger).to have_received(:info) do |data|
          obj = JSON.parse data
          expect(obj['name']).to eq('activity_throttled')
          expect(obj['properties']['event_properties']['matched']).to eq('auth/ip')
          expect(obj['properties']['event_properties'].keys).to include(
            'start',
            'finish',
            'req_id',
            'details',
          )
        end
      end
    end

    context 'with frequent attempts (other)' do
      before do
        freeze_time do
          6.times do
            get api_service_providers_path, headers: auth_header
          end
        end
      end

      it 'blocks access' do
        expect(response).to_not have_http_status(:ok)
        expect(request.env['rack.attack.match_type']).to eq(:blocklist)
      end

      it 'logs the blocklist action' do
        expect(logger).to have_received(:info) do |data|
          obj = JSON.parse data
          expect(obj['name']).to eq('blocklisted')
          expect(obj['properties']['event_properties']['matched']).to eq(
            'suspicious basic auth usage',
          )
          expect(obj['properties']['event_properties'].keys).to include('start', 'finish',
'req_id', 'ip', 'email')
          expect(obj['properties']['event_properties']['email']).to eq(test_user.email)
        end
      end
    end
  end
end
