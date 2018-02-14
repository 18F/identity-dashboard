require 'rails_helper'

describe ServiceProvider do
  describe 'Associations' do
    it { should belong_to(:user) }
    it { should belong_to(:group) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:issuer) }

    it 'validate that issuer is formatted correctly' do
      valid_service_provider = build(
        :service_provider,
        issuer: 'urn:gov:gsa:SAML:2.0.profiles:sp:sso:GSA:app',
      )

      expect(valid_service_provider.valid?).to eq(true)
    end

    it 'validates that all redirect_uris are absolute, parsable uris' do
      valid_sp = build(:service_provider, redirect_uris: ['http://foo.com'])
      missing_protocol_sp = build(:service_provider, redirect_uris: ['foo.com'])
      relative_uri_sp = build(:service_provider, redirect_uris: ['/asdf/hjkl'])
      bad_uri_sp = build(:service_provider, redirect_uris: [' http://foo.com'])

      expect(valid_sp).to be_valid
      expect(missing_protocol_sp).to_not be_valid
      expect(relative_uri_sp).to_not be_valid
      expect(bad_uri_sp).to_not be_valid
    end

    it 'allows redirect_uris to be empty' do
      sp = build(:service_provider, redirect_uris: [])
      expect(sp).to be_valid
    end
  end

  let(:service_provider) { build(:service_provider) }

  it { should have_readonly_attribute(:issuer) }

  describe '#service_provider=' do
    it 'should filter out nil and empty strings' do
      service_provider.redirect_uris = ['https://foo.com', nil, 'http://bar.com', '']

      expect(service_provider.redirect_uris).to eq(['https://foo.com', 'http://bar.com'])
    end
  end
end
