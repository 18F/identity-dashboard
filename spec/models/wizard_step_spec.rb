require 'rails_helper'

RSpec.describe WizardStep, type: :model do
  # Substitute for the method that exists in controllers
  def policy_scope(user)
    Pundit.policy_scope(user, WizardStep)
  end

  # Skip step 0 as it currently has no form data
  let(:random_form_step) { WizardStep::STEPS[1..-1].sample }

  let(:first_user) { create(:user) }

  describe '#find_or_intialize' do
    context 'with nothing relevant in the database' do
      it 'populates wizard_form_data defaults' do
        scoped_model = policy_scope(first_user).find_or_initialize_by(step_name: random_form_step)
        expect(scoped_model.wizard_form_data).to eq(WizardStep::STEP_DATA[random_form_step].fields)
      end
    end
  end

  describe 'dynamic form properties' do
    it 'populates all properties for all steps' do
      WizardStep::STEPS.each do |step_name|
        subject = WizardStep.new(step_name:)
        WizardStep::STEP_DATA[step_name].fields.keys.each do |field_name|
          expect(subject.send field_name).to eq(WizardStep::STEP_DATA[step_name].fields[field_name])
        end
      end
    end

    it 'pulls wizard_form_data back out' do
      expected_name = "Test name #{rand(1..10000)}"
      subject = WizardStep.new(step_name: 'settings')
      subject.wizard_form_data = { friendly_name: expected_name }
      expect(subject.friendly_name).to eq(expected_name)
    end
  end

  it 'throws an error with an invalid step name' do
    bad_name = "random #{rand(1..10000)}"
    invalidating_step = WizardStep.new
    expect do
      invalidating_step.step_name = bad_name
    end.to raise_error(ArgumentError, "Invalid WizardStep '#{bad_name}'.")
  end

  describe '#get_step' do
    let(:step_name_to_find) { WizardStep::STEP_DATA.keys.sample }
    let(:user) { create(:user) }

    it 'returns the subject if the subject is the matching step' do
      subject = create(:wizard_step, step_name: step_name_to_find)
      result = subject.get_step(step_name_to_find)
      expect(result).to be(subject)
    end

    it 'pulls the relevant step out of the database' do
      subject = create(:wizard_step,
        step_name: (WizardStep::STEP_DATA.keys - [step_name_to_find]).sample,
        user: user)
      expected_result = create(:wizard_step, step_name: step_name_to_find, user: user)
      expect(subject.get_step(step_name_to_find)).to eq(expected_result)
    end

    it 'builds a new step if no matching step exists' do
      subject = create(:wizard_step,
        step_name: (WizardStep::STEP_DATA.keys - [step_name_to_find]).sample,
        user: user)
      a_different_user = create(:user)
      absent_result = create(:wizard_step, step_name: step_name_to_find, user: a_different_user)
      expected_result = WizardStep.find_or_initialize_by(step_name: step_name_to_find, user: user)
      actual = subject.get_step(step_name_to_find)
      expect(actual).to_not eq(absent_result)
      expect(actual.attributes).to eq(expected_result.attributes)
      expect(actual).to_not be_persisted
    end
  end

  context 'step "settings"' do
    subject { build(:wizard_step, step_name: 'settings') }

    describe '#valid?' do
      it 'validates good wizard_form_data' do
        subject.wizard_form_data = {
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
    subject do
      build(:wizard_step, user: first_user, step_name: 'authentication', wizard_form_data: {
        ial: 1,
        default_aal: 0,
        attribute_bundle: [],
      })
    end

    describe '#valid?' do
      it 'validates good wizard_form_data' do
        expect(subject.valid?).to be(true), subject.errors.full_messages.join
      end
    end

    describe '#invalid?' do
      before do
        create(:wizard_step, user: first_user, step_name: 'protocol', wizard_form_data: {
          identity_protocol: 'saml',
        })
      end

      it 'fails with bad wizard_form_data' do
        subject.wizard_form_data = {
          ial: 2,
        }
        expect(subject).to_not be_valid
        expect(subject.errors[:attribute_bundle]).to include('Attribute bundle cannot be empty')
      end
    end
  end

  context 'step "issuer"' do
    let(:test_issuer) { "test:sso:#{rand(1..1000)}" }

    describe '#valid?' do
      subject { build(:wizard_step, step_name: 'issuer') }
      it 'is not valid by default' do
        expect(subject).to_not be_valid
        expect(subject.errors[:issuer]).to include("can't be blank")
      end

      it 'is valid with an issuer set' do
        expect(subject).to allow_value({ 'issuer' => test_issuer }).for(:wizard_form_data)
      end

      it 'is invalid if issuer already exists' do
        expect(ServiceProvider).to receive(:where).with(issuer: test_issuer).and_return(
          [ServiceProvider.new(issuer: test_issuer)],
        )
        subject.wizard_form_data['issuer'] = test_issuer
        expect(subject).to_not be_valid
        expect(subject.errors[:issuer]).to include('already in use')
      end

      it 'is valid if the issuer is for the service_provider you are editing' do
        user = create(:user, :with_teams)
        app_to_edit = create(:service_provider, issuer: test_issuer, team: user.teams.sample)
        in_use_issuer = "#{test_issuer}:#{rand(1..1000)}"
        _other_service_provder = create(:service_provider,
                                        # team doesn't matter — should fail regardless of team
                                        issuer: in_use_issuer)
        create(:wizard_step, step_name: 'hidden', user: user, wizard_form_data: {
          service_provider_id: app_to_edit.id,
        })
        issuer_step = build(:wizard_step, step_name: 'issuer', user: user)
        issuer_step.wizard_form_data = { issuer: test_issuer }
        expect(issuer_step).to be_valid

        issuer_step.wizard_form_data = { issuer: in_use_issuer }
        expect(issuer_step).to_not be_valid
      end
    end
  end

  context 'step "logo_and_cert"' do
    let(:good_logo) { fixture_file_upload('logo.svg', 'image/svg+xml') }

    describe '#certificates' do
      let(:certs) { nil }

      subject { build(:wizard_step, step_name: 'logo_and_cert', wizard_form_data: { certs: }) }

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

        it 'can remove one and retain the other' do
          serial_to_remove = [200, 300].sample
          removed_serial = subject.remove_certificate(serial_to_remove)
          expect(removed_serial).to be(serial_to_remove)
          expect(subject.certs.count).to be(1)
          remaining_serial = OpenSSL::X509::Certificate.new(subject.certs.first).serial
          expected_remaining_serial = ([200, 300] - [serial_to_remove]).first
          expect(remaining_serial.to_i).to be(expected_remaining_serial)
        end
      end

      context 'with an existing logo' do
        let(:good_logo) { fixture_file_upload('logo.svg') }
        let(:good_logo_checksum) do
          OpenSSL::Digest.base64digest('MD5', fixture_file_upload('logo.svg').read)
        end
        let(:empty_string_checksum) { OpenSSL::Digest.base64digest('MD5', '') }
        let(:unsized_logo) { fixture_file_upload('../logo_without_size.svg') }
        let(:unsized_logo_checksum) do
          OpenSSL::Digest.base64digest('MD5', fixture_file_upload('../logo_without_size.svg').read)
        end

        let(:step_with_logo) do
          this_step = create(:wizard_step, step_name: 'logo_and_cert')
          this_step.attach_logo(good_logo)
          this_step.save!
          this_step
        end

        it 'will not replace a good logo with a bad logo' do
          expect(step_with_logo.logo_file.checksum).to eq(good_logo_checksum)
          step_with_logo.attach_logo(unsized_logo)
          expect(step_with_logo).to_not be_valid
          step_with_logo.reload
          step_with_logo.logo_file.reload
          expect(step_with_logo.logo_file.checksum).to_not eq(empty_string_checksum)
          expect(step_with_logo.logo_file.checksum).to eq(good_logo_checksum)
          expect(step_with_logo.logo_name).to eq('logo.svg')
        end
      end
    end

    describe '#remove_certificate' do
      subject { build(:wizard_step, step_name: 'logo_and_cert', wizard_form_data: { certs: }) }
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
      subject { build(:wizard_step, step_name: 'logo_and_cert') }

      it 'is valid with blank wizard_form_data' do
        expect(subject.wizard_form_data['certs']).to be_empty
        expect(subject.wizard_form_data['logo_name']).to be_empty
        expect(subject.wizard_form_data['remote_logo_key']).to be_empty
        expect(subject).to be_valid
      end

      it 'is valid with good certs and uploads' do
        subject.attach_logo(good_logo)
        subject.certs << build_pem
        expect(subject.wizard_form_data['certs']).to_not be_empty
        expect(subject.wizard_form_data['logo_name']).to_not be_empty
        expect(subject.wizard_form_data['remote_logo_key']).to_not be_empty
        expect(subject).to be_valid
      end

      it 'is valid with a good upload that has been persisted' do
        subject.attach_logo(good_logo)
        subject.certs << build_pem
        subject.save!
        subject.valid?
        expect(subject.wizard_form_data['certs']).to_not be_empty
        expect(subject.wizard_form_data['logo_name']).to_not be_empty
        expect(subject.wizard_form_data['remote_logo_key']).to_not be_empty
        expect(subject).to be_valid
      end

      it 'has errors with bad certs and bad uploads' do
        subject.certs << 'invalid cert'
        subject.attach_logo(fixture_file_upload('testcert.pem', 'image/svg+xml'))
        expect(subject.wizard_form_data['certs']).to_not be_empty
        expect(subject.wizard_form_data['logo_name']).to_not be_empty
        expect(subject.wizard_form_data['remote_logo_key']).to_not be_empty
        expect(subject).to_not be_valid
        expect(subject.errors[:certs]).to_not be_blank
        expect(subject.errors[:logo_file]).
          to eq(['The file you uploaded (testcert.pem) is not a PNG or SVG'])
      end
    end

    describe '#pending_or_current_logo_data' do
      it 'returns false if the step is not "logo_and_cert"' do
        not_logo_step = (WizardStep::STEP_DATA.keys - ['logo_and_cert']).sample
        subject = build(:wizard_step, step_name: not_logo_step)
        expect(subject.pending_or_current_logo_data).to be_falsey
        expect { subject.logo_name }.to raise_error(NoMethodError)
        expect { subject.remote_logo_key }.to raise_error(NoMethodError)
      end

      it 'returns the data if the logo has been attached' do
        logo_step = build(:wizard_step, step_name: 'logo_and_cert')
        logo_step.attach_logo(good_logo)
        expect(logo_step.pending_or_current_logo_data).to eq(good_logo.read)
      end
    end

    describe '#attach_logo' do
      # Other behavior of `#attach_logo` is covered in the `#valid?` tests
      it 'does nothing if the step is not "logo_and_cert"' do
        not_logo_step = (WizardStep::STEP_DATA.keys - ['logo_and_cert']).sample
        subject = build(:wizard_step, step_name: not_logo_step)
        subject.attach_logo(good_logo)
        expect(subject.logo_file.blob).to be_nil
        expect { subject.logo_name }.to raise_error(NoMethodError)
        expect { subject.remote_logo_key }.to raise_error(NoMethodError)
      end
    end
  end

  describe '.all_step_data_for_user' do
    let(:subject_user) { create(:user) }

    it 'concatenates all the latest steps for a user' do
      created_steps = WizardStep::STEPS.map do |step_name|
        create(:wizard_step, step_name: step_name, user: subject_user )
      end
      ignored_user = create(:user)
      extra_step = create(:wizard_step, step_name: 'issuer', user: ignored_user, wizard_form_data: {
        issuer: 'issuer string that should not appear',
      })

      all_step_data = created_steps.map(&:wizard_form_data).reduce(&:merge)
      expect(WizardStep.all_step_data_for_user(subject_user)).to eq(all_step_data)
      expect(WizardStep.all_step_data_for_user(subject_user).values).
        to_not include(extra_step.issuer)

      all_field_names = WizardStep::STEPS.map do |step_name|
        WizardStep::STEP_DATA[step_name].fields
      end.reduce(&:merge).keys
      expect(WizardStep.all_step_data_for_user(subject_user).keys.sort).to eq(all_field_names.sort)
    end

    it 'will stop returning wizard_form_data that have been deleted' do
      test_issuer = "test:issuer:#{rand(1..100)}"
      create(:wizard_step, step_name: 'issuer',
        user: subject_user,
        wizard_form_data: { issuer: test_issuer })
      expect(WizardStep.all_step_data_for_user(subject_user)).to eq({ 'issuer' => test_issuer })
      WizardStep.where(user: subject_user, step_name: 'issuer').delete_all
      expect(WizardStep.all_step_data_for_user(subject_user).keys).
        to_not include('issuer')
    end

    it 'returns an empty hash when no data has been saved' do
      expect(WizardStep.all_step_data_for_user(subject_user)).to eq({})
    end
  end

  describe '.steps_from_service_provider' do
    let(:valid_data_to_hide) do
      {
        active: true,
        allow_prompt_login: true,
        approved: true,
        email_nameid_format_allowed: true,
        metadata_url: 'https://localhost/metadata',
      }
    end

    let(:original_user) { create(:user) }
    let(:ui_user) { create(:user) }

    let(:all_attributes_service_provider) do
      create(
        :service_provider,
        **valid_data_to_hide,
        user: original_user,
      )
    end

    it 'puts all attributes into a step' do
      wizard_steps = WizardStep.steps_from_service_provider(
        all_attributes_service_provider,
        ui_user,
      )
      hidden_step = wizard_steps.find { |s| s.step_name == 'hidden' }

      valid_data_to_hide.each do |(k, v)|
        expect(hidden_step.public_send(k)).to eq(v)
      end
      expect(hidden_step.service_provider_id).to eq(all_attributes_service_provider.id)
      expect(hidden_step.service_provider_user_id).to eq(original_user.id)

      wizard_steps.each do |built_step|
        expect(built_step.user).to eq(ui_user)
      end
    end
  end
end
