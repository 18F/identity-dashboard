require 'rails_helper'

RSpec.describe Api::SecurityEventsController do
  describe '#create' do
    subject(:action) { post :create, body: }

    let(:idp_private_key) { OpenSSL::PKey::RSA.new(2048) }
    let(:idp_public_key) { idp_private_key.public_key }

    before { allow(IdpPublicKeys).to receive(:all).and_return([idp_public_key]) }

    context 'with a valid JWT' do
      let(:user) { create(:user) }

      let(:payload) do
        {
          jti: SecureRandom.hex,
          iat: Time.zone.now.to_i,
          events: {
            'https://schemas.openid.net/secevent/risc/event-type/account-purged' => {
              subject: {
                subject_type: 'iss-sub',
                sub: user.uuid,
                iss: 'https://idp.example.login.gov',
              },
            },
          },
        }
      end

      let(:body) do
        JWT.encode(payload, idp_private_key, 'RS256', typ: 'secevent+jwt')
      end

      it 'creates a JWT and 201s' do
        expect { action }.to(change { SecurityEvent.count })

        expect(response).to be_created
      end
    end

    context 'with an invalid JWT' do
      let(:body) { 'aaaa' }

      it 'logs a warning and does not create a SecurityEvent' do
        expect(Rails.logger).to receive(:warn)

        expect { action }.to_not(change { SecurityEvent.count })

        expect(response).to be_bad_request
      end
    end
  end
end
