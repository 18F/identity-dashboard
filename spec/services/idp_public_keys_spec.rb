require 'rails_helper'

RSpec.describe IdpPublicKeys do
  subject(:loader) { IdpPublicKeys.new(idp_url: 'http://idp.example.com') }

  describe '#load_all' do
    let(:public_keys) do
      3.times.map do
        OpenSSL::PKey::RSA.new(2048).public_key
      end
    end

    it 'loads from the IDP' do
      stub_request(:get, 'http://idp.example.com/.well-known/openid-configuration').
        to_return(body: {
          jwks_uri: 'http://idp.example.com/certs',
        }.to_json)

      stub_request(:get, 'http://idp.example.com/certs').
        to_return(body: {
          keys: public_keys.map { |key| JSON::JWK.new(key) },
        }.to_json)

      expect(loader.load_all.map(&:to_pem)).to eq(public_keys.map(&:to_pem))
    end
  end
end
