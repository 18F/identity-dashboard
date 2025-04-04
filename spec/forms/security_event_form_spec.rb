require 'rails_helper'

RSpec.describe SecurityEventForm do
  subject(:form) { SecurityEventForm.new(body: jwt) }

  let(:idp_private_key) { OpenSSL::PKey::RSA.new(2048) }
  let(:idp_public_key) { idp_private_key.public_key }
  before { allow(IdpPublicKeys).to receive(:all).and_return([idp_public_key]) }

  let(:jwt) { JWT.encode(payload, idp_private_key, 'RS256', typ: 'secevent+jwt') }
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

  describe '#submit' do
    context 'with a valid JWT' do
      it 'returns [true, nil]' do
        success, errors = form.submit
        expect(success).to eq(true)
        expect(errors).to be_nil
      end

      it 'records the event in the database' do
        expect { form.submit }.to(change { SecurityEvent.count }.by(1))

        security_event = SecurityEvent.last
        aggregate_failures do
          expect(security_event.user).to eq(user)
          expect(security_event.event_type).
            to eq('https://schemas.openid.net/secevent/risc/event-type/account-purged')
          expect(security_event.uuid).to eq(payload[:jti])
          expect(security_event.issued_at.to_i).to eq(payload[:iat])
          expect(JSON.parse(security_event.raw_event)).to eq(JSON.parse(payload.to_json))
        end
      end
    end

    context 'when encoded with an unknown cert' do
      let(:idp_public_key) do
        # generate another random cert and use its public key
        OpenSSL::PKey::RSA.new(2048).public_key
      end

      it 'returns [false, errors]' do
        success, errors = form.submit
        expect(success).to eq(false)
        expect(errors[:jwt]).to include('could not verify JWT with any known keys')
      end
    end

    context 'with an empty payload' do
      let(:payload) { {} }

      it 'returns [false, errors]' do
        success, errors = form.submit
        expect(success).to eq(false)
        expect(errors[:payload]).to include("can't be blank")
      end
    end

    context 'with no event' do
      before { payload.delete(:events) }

      it 'returns [false, errors]' do
        success, errors = form.submit
        expect(success).to eq(false)
        expect(errors[:event_type]).to include("can't be blank")
      end
    end

    context 'with an unknown subject_type' do
      before do
        payload[:events].first.last[:subject][:subject_type] = 'foobar'
      end

      it 'returns [false, errors]' do
        success, errors = form.submit
        expect(success).to eq(false)
        expect(errors[:subject_type]).to include('unknown subject_type foobar')
      end
    end

    context 'with a iss-sub for an unknown user' do
      before do
        payload[:events].first.last[:subject][:sub] = 'not-a-user-uuid'
      end

      it 'returns [false, errors]' do
        success, errors = form.submit
        expect(success).to eq(false)
        expect(errors[:user]).to include("can't be blank")
      end
    end
  end
end
