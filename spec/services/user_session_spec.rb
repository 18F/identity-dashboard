require 'rails_helper'

describe UserSession do
  describe '#call' do
    let(:email) { 'test@test.com' }
    let!(:user) { create(:user, email:) }
    let(:uuid) { '123-asdf-qwerty' }

    let(:auth_hash) do
      {
        'email' => email,
        'uuid' => uuid,
      }
    end

    subject { described_class.new(auth_hash).call }

    context 'when the user exists' do
      it 'returns the user' do
        expect(subject).to eq(user)
        expect(subject.uuid).to eq(uuid)
      end
    end

    context 'when the user email ends with a allowlisted tld' do
      let(:email) { 'test@test.agency.gov' }

      it 'returns the user' do
        expect(subject).to eq(user)
        expect(subject.uuid).to eq(uuid)
      end
    end

    context 'when the user does not exist and does not have a allowlisted email' do
      it 'returns nil' do
        auth_hash['email'] = 'test@bad.email'
        expect(subject).to eq(nil)
      end
    end

    context 'when the user does not exist and does have a allowlisted email' do
      it 'returns nil' do
        auth_hash['email'] = 'test@gsa.gov'
        expect(subject.email).to eq(auth_hash['email'])
      end
    end

    context 'in a prod_like_env' do 
      before do
        allow(IdentityConfig.store).to receive_messages(prod_like_env: true)
      end

      it 'does not create a user for a new user login' do
        auth_hash['email'] = 'test@gsa.gov'
        expect(subject).to eq(nil)
      end
    end
  end
end
