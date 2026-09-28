require 'rails_helper'
RSpec.describe WizardSteps::LogoAndCertStep do
  let(:user) { create(:user) }
  let(:certs) { [] }
  let(:logo_name) { '' }
  let(:remote_logo_key) { '' }
  let(:identity_protocol) { 'openid_connect_private_key_jwt' }
  let(:logo) { fixture_file_upload('logo.svg') }
  let(:wizard_form_data) do
    {
      certs:,
      logo_name:,
      remote_logo_key:,
    }.as_json
  end
  let(:wizard_step) do
    create(:wizard_step, user:, step_name: 'logo_and_cert', wizard_form_data:)
  end

  subject { described_class.new(wizard_step) }

  before do
    create(:wizard_step, user:, step_name: 'protocol', wizard_form_data: {
      identity_protocol:,
    })
  end

  describe '.fields' do
    it 'returns the expected fields' do
      expect(described_class.fields).to eq(
        {
          certs: [],
          logo_name: '',
          remote_logo_key: '',
        },
      )
    end
  end

  describe '.step_name' do
    it 'returns "logo_and_cert"' do
      expect(described_class.step_name).to eq 'logo_and_cert'
    end
  end

  describe '#init' do
    it 'sets the wizard_step attribute' do
      expect(subject.instance_variable_get(:@wizard_step)).to eq wizard_step
    end
  end

  describe '#certificates' do
    describe 'when certs is nil' do
      let(:certs) { nil }

      it 'is an empty array' do
        expect(subject.certificates).to eq([])
      end
    end

    describe 'when certs is empty' do
      it 'is an empty array' do
        expect(subject.certificates).to eq([])
      end
    end

    describe 'when the PEM data is invalid' do
      let(:certs) { ['i-am-not-a-pem'] }

      it 'is a null certificate' do
        expect(subject.certificates.first.issuer).to eq('Null Certificate')
        expect(subject.certificates.first.not_before).to eq(Time.zone.at(0))
        expect(subject.certificates.first.not_after).to eq(Time.zone.at(0))
      end
    end

    describe 'when there are multiple certs' do
      let(:certs) { [build_pem(serial: 200), build_pem(serial: 300)] }

      it 'wraps them as ServiceProviderCertificates' do
        wrapped = certs.map do |cert|
          ServiceProviderCertificate.new(OpenSSL::X509::Certificate.new(cert))
        end

        expect(subject.certificates).to eq(wrapped)
      end
    end
  end

  describe '#remove_certificate' do
    describe 'when removing a serial that matches in the certs array' do
      let(:certs) { [build_pem(serial: 100), build_pem(serial: 200), build_pem(serial: 300)] }

      it 'removes that cert' do
        expect { subject.remove_certificate(200) }
          .to(change { subject.certificates.size }.from(3).to(2))

        has_serial = subject.certificates.any? { |cert| cert.serial.to_s == '200' }
        expect(has_serial).to be false
      end

      it 'returns the serial it was given' do
        expect(subject.remove_certificate(200)).to eq(200)
      end
    end

    describe 'when removing a serial that does not exist' do
      let(:certs) { [build_pem(serial: 200), build_pem(serial: 300)] }

      it 'does not remove anything' do
        expect { subject.remove_certificate(100) }.to_not(change { subject.certificates.size })
      end
    end

    describe 'when the certs array holds invalid PEM data' do
      let(:certs) { ['i-am-not-a-pem'] }

      it 'does not remove anything' do
        expect { subject.remove_certificate(100) }.to_not(change { subject.certificates.size })
      end
    end
  end

  describe '#attach_logo' do
    it 'attaches the logo file' do
      subject.attach_logo(logo)

      expect(wizard_step.logo_file).to be_attached
    end

    it 'records the logo name and remote key in the wizard_form_data' do
      subject.attach_logo(logo)

      expect(wizard_step.wizard_form_data['logo_name']).to eq('logo.svg')
      expect(wizard_step.wizard_form_data['remote_logo_key']).to eq(wizard_step.logo_file.key)
    end

    it 'leaves the other fields alone' do
      existing_cert = build_pem
      wizard_step.wizard_form_data['certs'] = [existing_cert]

      subject.attach_logo(logo)

      expect(wizard_step.wizard_form_data['certs']).to eq([existing_cert])
    end
  end

  describe '#pending_or_current_logo_data' do
    describe 'when no logo has been attached' do
      it 'returns nil' do
        expect(subject.pending_or_current_logo_data).to be_nil
      end
    end

    describe 'when the logo has been attached but not saved' do
      it 'returns the pending data' do
        subject.attach_logo(logo)

        expect(subject.pending_or_current_logo_data).to eq(fixture_file_upload('logo.svg').read)
      end
    end

    describe 'when the logo has been attached and saved' do
      it 'returns the persisted data' do
        subject.attach_logo(logo)
        wizard_step.save!
        wizard_step.reload

        expect(described_class.new(wizard_step).pending_or_current_logo_data)
          .to eq(fixture_file_upload('logo.svg').read)
      end
    end
  end

  describe 'validations' do
    describe 'when all attributes are blank' do
      it 'is valid' do
        expect(subject.valid?).to be(true), subject.errors.full_messages.join
      end
    end

    describe 'when the certs and logo are both good' do
      let(:certs) { [build_pem] }

      it 'is valid' do
        subject.attach_logo(logo)

        expect(subject.valid?).to be(true), subject.errors.full_messages.join
      end
    end

    describe 'when a cert is not PEM-encoded' do
      let(:certs) { ['invalid cert'] }

      it 'is not valid' do
        expect(subject.valid?).to be false
        expect(subject.errors[:certs]).to eq(['Certificate is not PEM-encoded'])
      end
    end

    describe 'when a cert claims to be PEM-encoded but is malformed' do
      let(:certs) { ["----BEGIN CERTIFICATE----\nnope\n"] }

      it 'is not valid' do
        expect(subject.valid?).to be false
        expect(subject.errors[:certs]).to_not be_empty
      end
    end

    describe 'when the protocol is SAML and no cert is present' do
      let(:identity_protocol) { 'saml' }

      it 'is not valid' do
        expect(subject.valid?).to be false
        expect(subject.errors[:certs])
          .to eq([I18n.t('service_provider_form.errors.certs.saml_no_cert')])
      end
    end

    describe 'when the protocol is SAML and a cert is present' do
      let(:identity_protocol) { 'saml' }
      let(:certs) { [build_pem] }

      it 'is valid' do
        expect(subject.valid?).to be(true), subject.errors.full_messages.join
      end
    end

    describe 'when the logo is not a PNG or SVG' do
      it 'is not valid' do
        subject.attach_logo(fixture_file_upload('testcert.pem', 'image/svg+xml'))

        expect(subject.valid?).to be false
        expect(subject.errors[:logo_file])
          .to eq(['The file you uploaded (testcert.pem) is not a PNG or SVG'])
      end
    end

    describe 'when the logo extension does not match the content type' do
      it 'is not valid' do
        subject.attach_logo(fixture_file_upload('logo.svg'))
        allow(wizard_step.logo_file).to receive(:content_type).and_return('image/png')

        expect(subject.valid?).to be false
        expect(subject.errors[:logo_file]).to include(
          'The extension of the logo file you uploaded (logo.svg) does not match the content.',
        )
      end
    end

    describe 'when the SVG logo has no viewbox' do
      it 'is not valid' do
        subject.attach_logo(
          fixture_file_upload('../logo_without_size.svg', 'image/svg+xml'),
        )

        expect(subject.valid?).to be false
        expect(subject.errors[:logo_file]).to include(
          I18n.t(
            'service_provider_form.errors.logo_file.no_viewbox',
            filename: 'logo_without_size.svg',
          ),
        )
      end
    end

    describe 'when the SVG logo has a script tag' do
      it 'is not valid' do
        subject.attach_logo(
          fixture_file_upload('../logo_with_script.svg', 'image/svg+xml'),
        )

        expect(subject.valid?).to be false
        expect(subject.errors[:logo_file]).to include(
          I18n.t(
            'service_provider_form.errors.logo_file.has_script_tag',
            filename: 'logo_with_script.svg',
          ),
        )
      end
    end

    describe 'when the logo is larger than the maximum size' do
      it 'is not valid' do
        subject.attach_logo(fixture_file_upload('../big-logo.png', 'image/png'))

        expect(subject.valid?).to be false
        expect(subject.errors[:logo_file]).to include('must be less than 50kB')
      end
    end

    describe 'when replacing a good logo with a bad logo' do
      let(:logo_checksum) do
        OpenSSL::Digest.base64digest('MD5', fixture_file_upload('logo.svg').read)
      end

      it 'does not replace the good logo' do
        subject.attach_logo(logo)
        wizard_step.save!

        subject.attach_logo(fixture_file_upload('../logo_without_size.svg', 'image/svg+xml'))
        expect(subject.valid?).to be false

        wizard_step.reload
        wizard_step.logo_file.reload
        expect(wizard_step.logo_file.checksum).to eq(logo_checksum)
        expect(wizard_step.wizard_form_data['logo_name']).to eq('logo.svg')
      end
    end
  end
end
