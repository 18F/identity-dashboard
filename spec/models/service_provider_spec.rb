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
        issuer: 'urn:gov:gsa:SAML:2.0.profiles:sp:sso:GSA:app'
      )
      invalid_service_provider = build(
        :service_provider,
        issuer: 'i-dont-care-about-your-rules even a little'
      )

      expect(valid_service_provider.valid?).to eq(true)
      expect(invalid_service_provider.valid?).to eq(false)
      expect(invalid_service_provider.errors[:issuer]).to include(
        t('activerecord.errors.models.service_provider.attributes.issuer.invalid')
      )
    end

    it 'accepts a blank certificate' do
      sp = build(:service_provider, redirect_uris: [], saml_client_cert: '')

      expect(sp).to be_valid
    end

    it 'fails if certificate is present but not x509' do
      sp = build(:service_provider, redirect_uris: [], saml_client_cert: 'foo')

      expect(sp).to_not be_valid
      expect(sp.errors[:saml_client_cert]).
        to include(
          t('activerecord.errors.models.service_provider.attributes.saml_client_cert.invalid')
        )
    end

    it 'accepts a valid x509 certificate' do
      valid_cert = <<~CERT
        -----BEGIN CERTIFICATE-----
        MIIDAjCCAeoCCQDnptBMGdfBIjANBgkqhkiG9w0BAQsFADBCMQswCQYDVQQGEwJV
        UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHU2VhdHRsZTEMMAoGA1UE
        ChMDMThGMCAXDTE0MTAwODIzMzkzMVoYDzIxMDYwMTEyMjMzOTMxWjBCMQswCQYD
        VQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHU2VhdHRsZTEM
        MAoGA1UEChMDMThGMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1zps
        ODzA7AHnls/NaICXSuBjyRbmEmDsoAl6YC/3ljBfG8POZre5wTeSjkPaj/h70ai5
        DEWrG3PyEJ0D6QqwNjReChq3AFSSnPLZeRu11N4UVvScJwCpRMs2LD93BBfFy8VU
        SQIOsPdrpy9ct31aNzYhi7LF3GBgIwcwq3SLxaF+YYDbbGqHZ8XkjrQlQlRGOPc8
        dcKcl0azNqSP4jAp83sw2NsKNPgDpI3PCs3H4C2q0RV/V+A4EIXi/3brAmnwKSOA
        JZ2ZAUIjHkv/Y1kk1TzAcy6s/V5f5Mxb4BjXxdAB18umI+EnfHLupV2fScOYY833
        AHSpuBiY+b7UfYPU5QIDAQABMA0GCSqGSIb3DQEBCwUAA4IBAQCrjv4rCw3Qhpyv
        konOP/Yufxj/SwkaZdanJCnbOvndRk2qO57FQU9qPwUJOu8kws8Xat+A+4ow2hQl
        C0b4OlifwrYcnBK/hDOcMOOH/d8na2bzOSg7lkHMOK3luELxPqsnkrszwtqAYs6K
        cLk2AEacrkAG0DVfOqYOGtUGUrx5QDYutX2kz24VcZ10so4IfRYI4EJX/tF46lqy
        dp6KaRxeVNQo21CGhfzeBSqgd0tRicu9uHzI57nxCLIzSQoLT5c6geCl5LJ7DxS2
        kaNiHglqe6GyLbbp3Y5q45xyBGPtJVT6kR6XqK4sEJPRgznbDn2NDx0Ef9mxHdVP
        e0sZY2CS
        -----END CERTIFICATE-----
      CERT
      sp = build(:service_provider, redirect_uris: [], saml_client_cert: valid_cert)

      expect(sp).to be_valid
    end

    it 'does not validate issuer format on update' do
      service_provider = build(:service_provider, issuer: 'I am invalid :)')
      service_provider.save(validate: false)

      service_provider.friendly_name = 'Invalid issuer, but it\'s all good'

      expect(service_provider.valid?).to eq(true)
    end

    it 'validates that all redirect_uris are absolute, parsable uris' do
      valid_sp = build(:service_provider, redirect_uris: ['http://foo.com'])
      missing_protocol_sp = build(:service_provider, redirect_uris: ['foo.com'])
      relative_uri_sp = build(:service_provider, redirect_uris: ['/asdf/hjkl'])
      bad_uri_sp = build(:service_provider, redirect_uris: [' http://foo.com'])
      malformed_uri_sp = build(:service_provider, redirect_uris: ['super.foo.com:/result'])

      expect(valid_sp).to be_valid
      expect(missing_protocol_sp).to_not be_valid
      expect(relative_uri_sp).to_not be_valid
      expect(bad_uri_sp).to_not be_valid
      expect(malformed_uri_sp).to_not be_valid
    end

    it 'allows redirect_uris to be empty' do
      sp = build(:service_provider, redirect_uris: [])
      expect(sp).to be_valid
    end
  end

  let(:service_provider) { build(:service_provider) }

  it { should have_readonly_attribute(:issuer) }

  describe '#recently_approved?' do
    it 'detects when flag toggles to true' do
      expect(service_provider.recently_approved?).to eq false
      service_provider.approved = true
      service_provider.save!
      expect(service_provider.recently_approved?).to eq true
    end
  end

  describe '#service_provider=' do
    it 'should filter out nil and empty strings' do
      service_provider.redirect_uris = ['https://foo.com', nil, 'http://bar.com', '']

      expect(service_provider.redirect_uris).to eq(['https://foo.com', 'http://bar.com'])
    end
  end

  describe '#block_encryption' do
    it 'should default to aes256-cbc' do
      sp = build(:service_provider)
      expect(sp.block_encryption).to eq('aes256-cbc')
    end

    it 'allows setting to none' do
      sp = build(:service_provider)
      sp.block_encryption = 'none'
      expect(sp.block_encryption).to eq('none')
    end

    it 'rejects nonsense encryption values' do
      sp = build(:service_provider)
      expect do
        sp.block_encryption = 'someinvalidthing'
      end.to raise_error(ArgumentError, /not a valid block_encryption/)
    end
  end
end
