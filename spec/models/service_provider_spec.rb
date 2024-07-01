require 'rails_helper'
require 'nokogiri'

describe ServiceProvider do
  describe 'Associations' do
    it { should belong_to(:user) }
    it { should belong_to(:team) }
  end

  describe 'Attachments' do
    let(:service_provider) do
      create(
        :service_provider,
        issuer: 'urn:gov:gsa:SAML:2.0.profiles:sp:sso:GSA:app',
      )
    end
    let(:fixture_path) { File.expand_path('../fixtures', __dir__) }
    let(:filename) { 'logo.svg'}
    let(:parsed_xml) {Nokogiri::XML(File.read(fixture_path + '/' + filename))}

    before do
      allow(service_provider).to receive(:svg_xml).and_return(parsed_xml)
      service_provider.logo_file.attach(
        io: File.open(fixture_path + '/' + filename),
        filename:,
      )
    end

    describe 'logo that is a png file' do
      let(:filename) { 'logo.png' }

      it 'is valid' do
        expect(service_provider.logo_file).to be_attached
        expect(service_provider).to be_valid
      end

      describe 'extension is all caps' do
        before do
          service_provider.logo_file.filename = 'logo.PNG'
        end

        it 'is valid' do
          expect(service_provider.logo_file).to be_attached
          expect(service_provider).to be_valid
        end
      end

      describe 'logo is greater than 1 mb' do
        let(:filename) { 'big-logo.png' }

        it 'is not valid' do
          expect(service_provider).to_not be_valid

          expect(service_provider.errors.first.message).to eq(
            'Logo must be less than 1MB',
          )
        end
      end

      describe 'it has the wrong extension' do
        before do
          service_provider.logo_file.filename = 'logo.svg'
        end

        it 'is not valid' do
          expect(service_provider).to_not be_valid
          expect(service_provider.errors.first.message).to eq(
            'The extension of the logo file you uploaded (logo.svg) does not match the content.',
          )
        end
      end

      describe 'it has no file extension' do
        before do
          service_provider.logo_file.filename = 'logo'
        end

        it 'is not valid' do
          expect(service_provider).to_not be_valid

          expect(service_provider.errors.first.message).to eq(
            'The extension of the logo file you uploaded (logo) does not match the content.',
          )
        end
      end
    end

    describe 'logo that is an svg file' do
      it 'is valid' do
        expect(service_provider.logo_file).to be_attached
        expect(service_provider).to be_valid
      end

      describe 'it has the wrong extension' do
        before do
          service_provider.logo_file.filename = 'logo.png'
        end

        it 'is not valid' do
          expect(service_provider).to_not be_valid
          expect(service_provider.errors.first.message).to eq(
            'The extension of the logo file you uploaded (logo.png) does not match the content.',
          )
        end
      end

      describe 'extension is all caps' do
        before do
          service_provider.logo_file.filename = 'logo.SVG'
        end

        it 'is valid' do
          expect(service_provider.logo_file).to be_attached
          expect(service_provider).to be_valid
        end
      end

      describe 'it has no file extension' do
        before do
          service_provider.logo_file.filename = 'logo'
        end

        it 'is not valid' do
          expect(service_provider).to_not be_valid

          expect(service_provider.errors.first.message).to eq(
            'The extension of the logo file you uploaded (logo) does not match the content.',
          )
        end
      end

      describe 'it has no size attributes' do
        let(:filename) { 'logo_without_size.svg'}

        it 'is not valid' do
          expect(service_provider).to_not be_valid

          expect(service_provider.errors.first.message).to eq(
            'The logo file you uploaded (logo_without_size.svg) does not have a defined size. Please either add a width and height attribute or a viewBox attribute to your SVG and re-upload') # rubocop:disable Layout/LineLength
        end
      end

      describe 'it has a script in the xml' do
        let(:filename) { 'logo_with_script.svg'}

        it 'is not valid' do
          expect(service_provider).to_not be_valid

          expect(service_provider.errors.first.message).to eq(
            'The logo file you uploaded (logo_with_script.svg) contains one or more script tags. Please remove all script tags and re-upload') # rubocop:disable Layout/LineLength
        end
      end 
    end

    describe 'logo with a different file extension' do
      let(:filename) { 'invalid.txt' }

      it 'is not valid' do
        expect(service_provider).to_not be_valid
      end
    end
  end

  describe 'Validations' do
    it { should validate_presence_of(:friendly_name) }
    it { should validate_presence_of(:issuer) }

    it 'accepts a correctly formatted issuer' do
      valid_service_provider = build(
        :service_provider,
        issuer: 'urn:gov:gsa:SAML:2.0.profiles:sp:sso:GSA:app',
      )

      expect(valid_service_provider).to be_valid
    end

    it 'fails when issuer is formatted incorrectly' do
      invalid_service_provider = build(
        :service_provider,
        issuer: 'i-dont-care-about-your-rules even a little',
      )

      expect(invalid_service_provider).not_to be_valid
    end

    it 'accepts an incorrectly formatted issuer on update' do
      initially_valid_service_provider = create(
        :service_provider,
        issuer: 'urn:gov:gsa:SAML:2.0.profiles:sp:sso:GSA:app',
      )
      expect(initially_valid_service_provider).to be_valid

      initially_valid_service_provider.update(
        issuer: 'Valid - we only check for whitespace in issuer on create.',
      )
      expect(initially_valid_service_provider).to be_valid
    end

    it 'does not validate issuer format on update' do
      service_provider = build(:service_provider, issuer: 'I am invalid :)')
      service_provider.save(validate: false)

      service_provider.friendly_name = 'Invalid issuer, but it\'s all good'

      expect(service_provider).to be_valid
    end

    it 'provides an error message when issuer is formatted incorrectly' do
      invalid_service_provider = build(
        :service_provider,
        issuer: 'i-dont-care-about-your-rules even a little',
      )
      invalid_service_provider.valid?

      expect(invalid_service_provider.errors[:issuer]).to include(
        t('activerecord.errors.models.service_provider.attributes.issuer.invalid'),
      )
    end

    it 'accepts a blank certificate' do
      sp = build(:service_provider, redirect_uris: [], certs: [''])

      expect(sp).to be_valid
    end

    it 'fails if certificate is present but not x509' do
      sp = build(:service_provider, redirect_uris: [], certs: ['foo'])

      expect(sp).to_not be_valid
    end

    it 'provides an error message if certificate is present but not x509' do
      sp = build(:service_provider, redirect_uris: [], certs: ['foo'])
      sp.valid?

      expect(sp.errors[:certs]).to include('Certificate is a not PEM-encoded')
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
      sp = build(:service_provider, redirect_uris: [], certs: [valid_cert])

      expect(sp).to be_valid
    end

    it 'rejects invalid certs' do
      sp = build(:service_provider, certs: ['NOT A CERT'])

      expect(sp).to_not be_valid
    end

    it 'rejects DER encoded certs' do
      sp = build(:service_provider, certs: [OpenSSL::X509::Certificate.new(build_pem).to_der])

      expect(sp).to_not be_valid
    end

    it 'rejects private keys as PEMs' do
      sp = build(:service_provider, certs: [OpenSSL::PKey::RSA.new(2048).to_pem])

      expect(sp).to_not be_valid
    end

    it 'validates that all redirect_uris are absolute, parsable uris with no wildcards' do
      valid_sp = build(:service_provider, redirect_uris: ['http://foo.com'])
      valid_native_sp = build(:service_provider, redirect_uris: ['example-app:/result'])
      missing_scheme_sp = build(:service_provider, redirect_uris: ['foo.com'])
      relative_uri_sp = build(:service_provider, redirect_uris: ['/asdf/hjkl'])
      bad_uri_sp = build(:service_provider, redirect_uris: [' http://foo.com'])
      file_uri_sp = build(:service_provider, redirect_uris: ['file:///usr/sbin/evil_script.sh'])
      wildcard_uri = build(:service_provider, redirect_uris: ['https://app.me/*'])

      expect(valid_sp).to be_valid
      expect(valid_native_sp).to be_valid
      expect(missing_scheme_sp).to_not be_valid
      expect(relative_uri_sp).to_not be_valid
      expect(bad_uri_sp).to_not be_valid
      expect(file_uri_sp).to_not be_valid
      expect(wildcard_uri).to_not be_valid
    end

    it 'validates that the failure_to_proof_url is an absolute, parsable uri' do
      valid_sp = build(:service_provider, failure_to_proof_url: 'http://foo.com')
      valid_native_sp = build(:service_provider, failure_to_proof_url: 'example-app:/result')
      missing_scheme_sp = build(:service_provider, failure_to_proof_url: 'foo.com')
      relative_uri_sp = build(:service_provider, failure_to_proof_url: '/asdf/hjkl')
      bad_uri_sp = build(:service_provider, failure_to_proof_url: ' http://foo.com')
      malformed_uri_sp = build(:service_provider, failure_to_proof_url: 'super.foo.com:result')
      file_uri_sp = build(:service_provider,
                          failure_to_proof_url: 'file:///usr/sbin/evil_script.sh')

      expect(valid_sp).to be_valid
      expect(valid_native_sp).to be_valid
      expect(missing_scheme_sp).to_not be_valid
      expect(relative_uri_sp).to_not be_valid
      expect(bad_uri_sp).to_not be_valid
      expect(malformed_uri_sp).to_not be_valid
      expect(file_uri_sp).to_not be_valid
    end

    it 'validates that the push_notification_url is an absolute, parsable uri' do
      valid_sp = build(:service_provider, push_notification_url: 'http://foo.com')
      valid_native_sp = build(:service_provider, push_notification_url: 'example-app:/result')
      missing_scheme_sp = build(:service_provider, push_notification_url: 'foo.com')
      relative_uri_sp = build(:service_provider, push_notification_url: '/asdf/hjkl')
      bad_uri_sp = build(:service_provider, push_notification_url: ' http://foo.com')
      malformed_uri_sp = build(:service_provider, push_notification_url: 'super.foo.com:result')
      file_uri_sp = build(:service_provider,
                          push_notification_url: 'file:///usr/sbin/evil_script.sh')

      expect(valid_sp).to be_valid
      expect(valid_native_sp).to be_valid
      expect(missing_scheme_sp).to_not be_valid
      expect(relative_uri_sp).to_not be_valid
      expect(bad_uri_sp).to_not be_valid
      expect(malformed_uri_sp).to_not be_valid
      expect(file_uri_sp).to_not be_valid
    end

    it 'allows redirect_uris to be empty' do
      sp = build(:service_provider, redirect_uris: [])
      expect(sp).to be_valid
    end

    it 'validates the value of ial' do
      sp = build(:service_provider, ial: 1)
      expect(sp).to be_valid
      sp = build(:service_provider, ial: 2)
      expect(sp).to be_valid
      sp = build(:service_provider, ial: 3)
      expect(sp).not_to be_valid
      sp = build(:service_provider, ial: nil)
      expect(sp).to be_valid
    end

    it 'converts integer to friendly IAL string' do
      sp = build(:service_provider, ial: nil)
      expect(sp.ial_friendly).to eq(I18n.t('service_provider_form.ial_option_1'))
      sp = build(:service_provider, ial: 1)
      expect(sp.ial_friendly).to eq(I18n.t('service_provider_form.ial_option_1'))
      sp = build(:service_provider, ial: 2)
      expect(sp.ial_friendly).to eq(I18n.t('service_provider_form.ial_option_2'))
      sp = build(:service_provider, ial: 3)
      expect(sp.ial_friendly).to eq('3')
    end

    it 'converts integer to friendly AAL string' do
      sp = build(:service_provider, default_aal: nil)
      expect(sp.aal_friendly).to eq(I18n.t('service_provider_form.aal_option_default'))
      sp = build(:service_provider, default_aal: 1)
      expect(sp.aal_friendly).to eq(I18n.t('service_provider_form.aal_option_default'))
      sp = build(:service_provider, default_aal: 2)
      expect(sp.aal_friendly).to eq(I18n.t('service_provider_form.aal_option_2'))
      sp = build(:service_provider, default_aal: 3)
      expect(sp.aal_friendly).to eq(I18n.t('service_provider_form.aal_option_3'))
      sp = build(:service_provider, default_aal: 4)
      expect(sp.aal_friendly).to eq('4')
    end

    it 'validates the the attribute bundle according IAL and protocol' do
      ial_1_bundle = %w[email all_emails verified_at x509_subject x509_presented]
      ial_2_bundle = %w[first_name last_name dob ssn address1 address2 city state zipcode phone]
      empty_bundle = []

      saml_sp_ial1 = create(:service_provider, :saml, :with_ial_1)
      expect(saml_sp_ial1).to allow_value(empty_bundle).for(:attribute_bundle)
      expect(saml_sp_ial1).to allow_value(ial_1_bundle).for(:attribute_bundle)
      expect(saml_sp_ial1).not_to allow_value(ial_2_bundle).for(:attribute_bundle)
      expect(saml_sp_ial1).not_to allow_value(%w[gibberish]).for(:attribute_bundle)

      saml_sp_ial2 = create(:service_provider, :saml, :with_ial_2)
      expect(saml_sp_ial2).not_to allow_value(empty_bundle).for(:attribute_bundle)
      expect(saml_sp_ial2).to allow_value(ial_1_bundle).for(:attribute_bundle)
      expect(saml_sp_ial2).to allow_value(ial_2_bundle).for(:attribute_bundle)
      expect(saml_sp_ial2).not_to allow_value(%w[gibberish]).for(:attribute_bundle)

      oidc_sp_ial1 = create(:service_provider, :with_oidc_jwt, :with_ial_1)
      expect(oidc_sp_ial1).to allow_value(empty_bundle).for(:attribute_bundle)
      expect(oidc_sp_ial1).to allow_value(ial_1_bundle).for(:attribute_bundle)
      expect(oidc_sp_ial1).not_to allow_value(ial_2_bundle).for(:attribute_bundle)
      expect(oidc_sp_ial1).not_to allow_value(%w[gibberish]).for(:attribute_bundle)

      oidc_sp_ial2 = create(:service_provider, :with_oidc_jwt, :with_ial_2)
      expect(oidc_sp_ial2).to allow_value(empty_bundle).for(:attribute_bundle)
      expect(oidc_sp_ial2).to allow_value(ial_1_bundle).for(:attribute_bundle)
      expect(oidc_sp_ial2).to allow_value(ial_2_bundle).for(:attribute_bundle)
      expect(oidc_sp_ial2).not_to allow_value(%w[gibberish]).for(:attribute_bundle)

    end

    it 'sanitizes help text before saving' do
      sp_with_unsanitary_help_text = create(
          :service_provider,
          help_text: {
            'sign_in': { en: '<script>unsanitary script</script>' }, 'sign_up': {},
            'forgot_password': {}
          },
      )
      expect(sp_with_unsanitary_help_text.help_text['sign_in']['en']).to eq 'unsanitary script'
    end

    it 'permits the "target" attribute for links' do
      sp = create(
        :service_provider,
        help_text: {
          'sign_in' => { en: '<a href="#" target="_blank">link</a>' },
          'sign_up' => {},
          'forgot_password' => {},
        },
      )

      expect(sp.help_text['sign_in']['en']).to eq('<a href="#" target="_blank">link</a>')
    end

    it 'permits more complex HTML elements' do
      text = '<ol><li><strong>item1</strong></li></ol><ul><li><em>item2</em></li></ul>'
      sp = create(
        :service_provider,
        help_text: {
          'sign_in' => { en: text },
          'sign_up' => {},
          'forgot_password' => {},
        },
      )

      expect(sp.help_text['sign_in']['en']).to eq(text)
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

  describe '#certificates' do
    subject(:sp) { build(:service_provider, certs: certs) }
    let(:certs) { nil }

    context 'with nil' do
      let(:certs) { nil }

      it 'is an empty array' do
        expect(sp.certificates).to eq([])
      end
    end

    context 'with invalid PEM data' do
      let(:certs) { ['i-am-not-a-pem'] }

      it 'is a null certificate' do
        expect(sp.certificates.first.issuer).to eq('Null Certificate')
      end
    end

    context 'with multiple certs' do
      let(:certs) { [ build_pem(serial: 200), build_pem(serial: 300)] }

      it 'wraps them as ServiceProviderCertificates' do
        wrapped = certs.map do |cert|
          ServiceProviderCertificate.new(OpenSSL::X509::Certificate.new(cert))
        end

        expect(sp.certificates).to eq(wrapped)
      end
    end
  end

  describe '#remove_certificate' do
    subject(:sp) { build(:service_provider, certs: certs) }
    let(:certs) { nil }

    context 'when removing a serial that matches in the certs array' do
      let(:certs) { [ build_pem(serial: 100), build_pem(serial: 200), build_pem(serial: 300)] }

      it 'removes that cert' do
        expect { sp.remove_certificate(200) }.
          to(change { sp.certificates.size }.from(3).to(2))

        has_serial = sp.certificates.any? { |c| c.serial.to_s == '200' }
        expect(has_serial).to eq(false)
      end
    end

    context 'when removing a serial that does not exist' do
      let(:certs) { [ build_pem(serial: 200), build_pem(serial: 300)] }

      it 'does not remove anything' do
        expect { sp.remove_certificate(100) }.to_not(change { sp.certificates.size })
      end
    end
  end

  describe '#oidc?' do
    it 'returns false for SAML integrations' do
      sp = build(:service_provider, identity_protocol: 'saml')
      expect(!sp.oidc?)
    end
    it 'returns true for OIDC private_key_jwt integrations' do
      sp = build(:service_provider, identity_protocol: 'openid_connect_private_key_jwt')
      expect(sp.oidc?)
    end
    it 'returns true for OIDC PKCE integrations' do
      sp = build(:service_provider, identity_protocol: 'openid_connect_pkce')
      expect(sp.oidc?)
    end
  end
end
