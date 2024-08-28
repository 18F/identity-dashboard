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
  end
end
