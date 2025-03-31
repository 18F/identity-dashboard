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
    let(:filename) { 'logo.svg' }

    before do
      service_provider.logo_file.attach(fixture_file_upload(filename))
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
        let(:filename) { '../big-logo.png' }

        it 'is not valid' do
          expect(service_provider).to_not be_valid

          expect(service_provider.errors.first.message).to eq(
            'Logo must be less than 50kB',
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

      describe 'it has no viewBox attributes' do
        let(:filename) { '../logo_without_size.svg' }

        it 'is not valid' do
          expect(service_provider).to_not be_valid

          expect(service_provider.errors.first.message).to eq(I18n.t(
            'service_provider_form.errors.logo_file.no_viewbox',
            filename: 'logo_without_size.svg',
          ))
        end
      end

      describe 'it has a script in the xml' do
        let(:filename) { '../logo_with_script.svg' }

        it 'is not valid' do
          expect(service_provider).to_not be_valid

          expect(service_provider.errors.first.message).to eq(I18n.t(
            'service_provider_form.errors.logo_file.has_script_tag',
            filename: 'logo_with_script.svg',
          ))
        end
      end
    end

    describe 'logo with a different file extension' do
      let(:filename) { '../invalid.txt' }

      it 'is not valid' do
        expect(service_provider.errors[:logo_file]).to eq(
          ['The file you uploaded (invalid.txt) is not a PNG or SVG'],
        )
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

    it 'validates with the certs_are_pems validator' do
      validator = ServiceProvider.validators.find { |v| v.instance_of?(CertsArePemsValidator) }
      expect(validator).to receive(:validate).and_return(true)
      expect(service_provider).to be_valid
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

    it 'validates that the post_idv_follow_up_url is an absolute, parsable uri' do
      valid_sp = build(:service_provider, post_idv_follow_up_url: 'http://foo.com')
      valid_native_sp = build(:service_provider, post_idv_follow_up_url: 'example-app:/result')
      missing_scheme_sp = build(:service_provider, post_idv_follow_up_url: 'foo.com')
      relative_uri_sp = build(:service_provider, post_idv_follow_up_url: '/asdf/hjkl')
      bad_uri_sp = build(:service_provider, post_idv_follow_up_url: ' http://foo.com')
      malformed_uri_sp = build(:service_provider, post_idv_follow_up_url: 'super.foo.com:result')
      file_uri_sp = build(:service_provider,
                           post_idv_follow_up_url: 'file:///usr/sbin/evil_script.sh')

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

  describe '.new' do
    subject(:new_sp) { ServiceProvider.new }

    context 'in prod-like env' do
      before do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
      end
      it { expect(new_sp).to be_pending }
      it { expect(new_sp).to_not be_live }
      it { expect(new_sp).to_not be_rejected }
    end

    context 'not in prod-like env' do
      before do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(false)
      end
      it { expect(new_sp).to_not be_pending }
      it { expect(new_sp).to be_live }
      it { expect(new_sp).to_not be_rejected }
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
    subject(:sp) { build(:service_provider, certs:) }
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
    subject(:sp) { build(:service_provider, certs:) }
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
