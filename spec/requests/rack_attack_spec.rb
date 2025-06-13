require 'rails_helper'

RSpec.describe 'limiting suspicious requests' do
  let(:logger_double) { instance_double(EventLogger) }

  before do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.cache.store.clear
    allow(EventLogger).to receive(:new).and_return(logger_double)
    allow(logger_double).to receive(:track_event)
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

    context 'with frequent attempts' do
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
        expect(logger_double).to have_received(:track_event) do |name, data|
          expect(name).to eq('blocklisted')
          expect(data[:matched]).to eq('suspicious basic auth usage')
          expect(data.keys).to include(:start, :finish, :req_id)
        end
      end
    end
  end
end
