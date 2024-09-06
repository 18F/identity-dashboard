require 'rails_helper'

RSpec.describe WizardStep, type: :model do
  # Substitute for the method that exists in controllers
  def policy_scope(user)
    Pundit.policy_scope(user, WizardStep)
  end

  # Skip step 0 as it currently has no form data
  let(:random_form_step) { WizardStep::STEPS[1..-1].sample}

  let(:first_user) {create(:user)}

  describe '#find_or_intialize' do
    context 'with nothing relevant in the database' do
      it 'populates data defaults' do
        scoped_model = policy_scope(first_user).find_or_initialize_by(step_name: random_form_step)
        expect(scoped_model.data).to eq(WizardStep::STEP_DATA[random_form_step].fields)
      end
    end
  end

  describe 'dynamic form properties' do
    it 'populates all properties for all steps' do
      WizardStep::STEPS.each do |step_name|
        subject = WizardStep.new(step_name: step_name)
        WizardStep::STEP_DATA[step_name].fields.keys.each do |field_name|
          expect(subject.send field_name).to eq(WizardStep::STEP_DATA[step_name].fields[field_name])
        end
      end
    end

    it 'pulls data back out' do
      expected_name = "Test name #{rand(1..10000)}"
      subject = WizardStep.new(step_name: 'settings')
      subject.data = {friendly_name: expected_name}
      expect(subject.friendly_name).to eq(expected_name)
    end
  end

  context 'step "settings"' do
    subject { build(:wizard_step, step_name: 'settings')}

    describe '#valid?' do
      it 'validates good data' do
        subject.data = {
          app_name: 'something goes here',
          friendly_name: 'something friendly goes here',
          group_id: create(:team).id,
        }
        expect(subject.valid?).to be_truthy
        expect(subject.errors).to be_blank
      end

      it 'sets errors for all bad settings' do
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:app_name]).to eq(["can't be blank"])
        expect(subject.errors[:friendly_name]).to eq(["can't be blank"])
        expect(subject.errors[:group_id]).to eq(["can't be blank", 'is invalid'])
      end
    end
  end

  context 'step "authentication"' do
    let(:authentication_step) { 
      build(:wizard_step, step_name: 'authentication', data: {
        identity_protocol: 'openid_connect_private_key_jwt',
        ial: '1',
        default_aal: 'on',
      })
    }
    describe '#valid?' do
      it 'validates good data' do
        expect(authentication_step.valid?).to be(true), authentication_step.errors.messages
      end

      it 'fails with bad data' do
        authentication_step.data['ial'] = 2
        authentication_step.data['identity_protocol'] = 'saml'
        expect(authentication_step.valid?).to be_falsey
        bundle_errors = authentication_step.errors[:attribute_bundle]
        expect(bundle_errors).to eq(['Attribute bundle cannot be empty'])
      end
    end
  end

  context 'step "issuer"' do
    describe '#valid?' do
      subject { build(:wizard_step, step_name: 'issuer')}
      it 'is not valid by default' do
        expect(subject).to_not be_valid
        expect(subject.errors[:issuer]).to include("can't be blank")
      end

      it 'is valid with an issuer set' do
        expect(subject).to allow_value({'issuer' => "test:sso:#{rand(1..1000)}" }).for(:data)
      end
    end
  end

  context 'step "logo_and_cert"' do
    describe '#certificates' do
      let(:certs) { nil }
      subject { build(:wizard_step, step_name: 'logo_and_cert', data: {certs: certs}) }

      context 'with nil' do
        let(:certs) { nil }

        it 'is an empty array' do
          expect(subject.certificates).to eq([])
        end
      end

      context 'with invalid PEM data' do
        let(:certs) { ['i-am-not-a-pem'] }

        it 'is a null certificate' do
          expect(subject.certificates.first.issuer).to eq('Null Certificate')
        end
      end

      context 'with multiple certs' do
        let(:certs) { [ build_pem(serial: 200), build_pem(serial: 300)] }

        it 'wraps them as ServiceProviderCertificates' do
          wrapped = certs.map do |cert|
            ServiceProviderCertificate.new(OpenSSL::X509::Certificate.new(cert))
          end

          expect(subject.certificates).to eq(wrapped)
        end
      end
    end

    describe '#remove_certificate' do
      subject { build(:wizard_step, step_name: 'logo_and_cert', data: {certs: certs}) }
      let(:certs) { nil }

      context 'when removing a serial that matches in the certs array' do
        let(:certs) { [ build_pem(serial: 100), build_pem(serial: 200), build_pem(serial: 300)] }

        it 'removes that cert' do
          expect { subject.remove_certificate(200) }.
            to(change { subject.certificates.size }.from(3).to(2))

          has_serial = subject.certificates.any? { |c| c.serial.to_s == '200' }
          expect(has_serial).to eq(false)
        end
      end

      context 'when removing a serial that does not exist' do
        let(:certs) { [ build_pem(serial: 200), build_pem(serial: 300)] }

        it 'does not remove anything' do
          expect { subject.remove_certificate(100) }.to_not(change { subject.certificates.size })
        end
      end
    end

    describe '#valid?' do
      subject { build(:wizard_step, step_name: 'logo_and_cert')}

      it 'is valid with blank data' do
        expect(subject.data['certs']).to be_empty
        expect(subject.data['logo_name']).to be_empty
        expect(subject.data['remote_logo_key']).to be_empty
        expect(subject).to be_valid
      end

      it 'is valid with good certs and uploads' do
        subject.attach_logo(fixture_file_upload('logo.svg', 'image/svg+xml'))
        subject.certs << build_pem
        expect(subject.data['certs']).to_not be_empty
        expect(subject.data['logo_name']).to_not be_empty
        expect(subject.data['remote_logo_key']).to_not be_empty
        expect(subject).to be_valid
      end

      it 'has errors with bad certs and bad uploads' do
        subject.certs << 'invalid cert'
        subject.attach_logo(fixture_file_upload('testcert.pem', 'image/svg+xml'))
        expect(subject.data['certs']).to_not be_empty
        expect(subject.data['logo_name']).to_not be_empty
        expect(subject.data['remote_logo_key']).to_not be_empty
        expect(subject).to_not be_valid
        expect(subject.errors[:certs]).to_not be_blank
        expect(subject.errors[:logo_file]).
          to eq(['The file you uploaded (testcert.pem) is not a PNG or SVG'])
      end
    end
  end
end
