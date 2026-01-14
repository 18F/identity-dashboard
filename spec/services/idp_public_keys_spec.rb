require 'rails_helper'

RSpec.describe IdpPublicKeys do
  before { Rails.cache.clear }

  let(:public_keys) do
    3.times.map do
      OpenSSL::PKey::RSA.new(2048).public_key
    end
  end

  before do
    stub_request(:get, 'http://idp.example.com/.well-known/openid-configuration')
      .to_return(body: {
        jwks_uri: 'http://idp.example.com/certs',
      }.to_json)

    stub_request(:get, 'http://idp.example.com/certs')
      .to_return(body: {
        keys: public_keys.map { |key| JSON::JWK.new(key) },
      }.to_json)
  end

  describe '.all' do
    before do
      allow(Rails).to receive_message_chain(:configuration, :oidc, :[])
        .and_return('http://idp.example.com')
    end

    it 'caches the response from the IDP' do
      3.times { IdpPublicKeys.all }

      expect(a_request(:get, 'http://idp.example.com/.well-known/openid-configuration'))
        .to have_been_requested.once
      expect(a_request(:get, 'http://idp.example.com/certs'))
        .to have_been_requested.once
    end
  end

  subject(:loader) { IdpPublicKeys.new(idp_url: 'http://idp.example.com') }

  describe '#load_all' do
    it 'loads from the IDP' do
      expect(loader.load_all.map { |jwk| jwk.to_key.to_pem }).to eq(public_keys.map(&:to_pem))
    end
  end
end
