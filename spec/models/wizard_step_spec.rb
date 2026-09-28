require 'rails_helper'

RSpec.describe WizardStep, type: :model do
  # Substitute for the method that exists in controllers
  def policy_scope(user)
    Pundit.policy_scope(user, WizardStep)
  end

  # Skip step 0 as it currently has no form data
  let(:random_form_step) { WizardStep::STEPS[1..-1].sample }

  let(:first_user) { create(:user) }
  let(:logingov_admin) { create(:user, :logingov_admin) }

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
      expected_name = "Test name #{rand(1..10_000)}"
      subject = WizardStep.new(step_name: 'settings')
      subject.wizard_form_data = { friendly_name: expected_name }
      expect(subject.friendly_name).to eq(expected_name)
    end
  end

  it 'throws an error with an invalid step name' do
    bad_name = "random #{rand(1..10_000)}"
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

    # Behavior of #certificates, #remove_certificate, #attach_logo, and
    # #pending_or_current_logo_data lives in WizardSteps::LogoAndCertStep and is
    # covered in spec/models/wizard_steps/logo_and_cert_spec.rb. These examples
    # only cover that WizardStep delegates validation to that step object.
    describe '#valid?' do
      subject { build(:wizard_step, step_name: 'logo_and_cert') }

      it 'is valid with blank wizard_form_data' do
        expect(subject.wizard_form_data['certs']).to be_empty
        expect(subject.wizard_form_data['logo_name']).to be_empty
        expect(subject.wizard_form_data['remote_logo_key']).to be_empty
        expect(subject).to be_valid
      end

      it 'surfaces cert errors from the step object' do
        subject.certs << 'invalid cert'

        expect(subject).to_not be_valid
        expect(subject.errors[:certs]).to eq(['Certificate is not PEM-encoded'])
      end
    end
  end

  context 'step "redirects"' do
    let(:redirects_user) { create(:user) }
    let(:admin_user) { create(:user, :logingov_admin) }

    subject do
      create(:wizard_step, user: redirects_user, step_name: 'redirects', wizard_form_data: {
        push_notification_url: '',
        failure_to_proof_url: '',
        redirect_uris: '',
      })
    end

    describe '#valid?' do
      it 'validates good URLs' do
        subject.wizard_form_data = {
          push_notification_url: 'https://good.gov/',
          failure_to_proof_url: 'https://good.gov',
          redirect_uris: ['https://www.good.gov/'],
        }

        expect(subject.valid?).to be_truthy
        expect(subject.errors).to be_blank
      end

      it 'validates nil for unrequired URLs' do
        subject.wizard_form_data = {
          failure_to_proof_url: 'https://test.good.gov',
        }

        expect(subject.valid?).to be_truthy
        expect(subject.errors).to be_blank
      end

      it 'validates unchanged URLs' do
        subject.wizard_form_data = {
          push_notification_url: '',
          failure_to_proof_url: '',
          redirect_uris: '',
        }

        expect(subject.valid?).to be_truthy
        expect(subject.errors).to be_blank
      end

      describe 'production_ready' do
        subject do
          create(:wizard_step, user: admin_user, step_name: 'redirects')
        end
        before do
          create(:wizard_step, user: admin_user, step_name: 'settings', wizard_form_data: {
            prod_config: true,
          })
        end

        context 'admin_user' do
          subject do
            create(:wizard_step, user: admin_user, step_name: 'redirects')
          end

          it 'allows logingov_admin to use localhost URLs' do
            subject.wizard_form_data = {
              push_notification_url: 'http://localhost:3001/',
              failure_to_proof_url: 'https://localhost:3001',
              redirect_uris: ['https://localhost:3001/somepath'],
            }

            expect(subject.get_step('settings').wizard_form_data['prod_config']).to be_truthy
            expect(subject.valid?).to be_truthy
            expect(subject.errors).to be_blank
          end
        end

        context 'existing localhost URLs' do
          subject do
            create(:wizard_step, user: redirects_user, step_name: 'redirects', wizard_form_data: {
              push_notification_url: 'http://localhost:3001/',
              failure_to_proof_url: 'https://localhost:3001',
              redirect_uris: ['https://localhost:3001/somepath'],
            })
          end

          it 'is valid while the localhost URI is unchanged' do
            subject.wizard_form_data = {
              push_notification_url: 'http://localhost:3001/',
              failure_to_proof_url: 'https://localhost:3001',
              redirect_uris: ['https://localhost:3001/somepath'],
            }

            expect(subject.valid?).to be_truthy
            expect(subject.errors).to be_blank
          end

          it 'is valid when a localhost URI is updated to a valid TLD' do
            subject.wizard_form_data = {
              push_notification_url: 'http://good.gov/',
              failure_to_proof_url: 'https://good.gov',
              redirect_uris: ['https://good.gov/somepath'],
            }

            expect(subject.valid?).to be_truthy
            expect(subject.errors).to be_blank
          end
        end
      end
    end

    describe '#invalid?' do
      let(:user) { create(:user, :partner_admin) }

      it 'fails with an invalid host in redirect_uris' do
        subject.wizard_form_data = {
          redirect_uris: ["http://local'host:0"],
        }

        expect(subject).to_not be_valid
        expect(subject.errors[:redirect_uris]).to include(
          "http://local'host:0 has an invalid host",
        )
      end

      it 'fails with bad URLs' do
        subject.wizard_form_data = {
          push_notification_url: 'http//badgov/',
          failure_to_proof_url: 'bad.gov',
        }

        expect(subject).to_not be_valid
        expect(subject.errors[:push_notification_url]).to include(
          'http//badgov/ is not a valid URI',
        )
        expect(subject.errors[:failure_to_proof_url]).to include('bad.gov is not a valid URI')
        # TODO: add `redirect_uri` error reporting is broken. Add tests later.
      end

      it 'fails with wildcards in URLs' do
        subject.wizard_form_data = {
          push_notification_url: 'https://*.good.gov',
        }

        expect(subject).to_not be_valid
        expect(subject.errors[:push_notification_url]).to include(
          'https://*.good.gov contains invalid wildcards(*)',
        )
      end

      describe 'production_ready' do
        subject do
          create(:wizard_step, user: first_user, step_name: 'settings', wizard_form_data: {
            prod_config: true,
          })
          create(:wizard_step, user: first_user, step_name: 'redirects')
        end

        it 'fails when a non-logingov_admin uses localhost' do
          subject.current_user_id = user.id
          subject.wizard_form_data = {
            push_notification_url: 'http://localhost:3001/',
            failure_to_proof_url: 'https://localhost:3001',
            redirect_uris: ['https://localhost:3001/somepath'],
          }

          expect(subject.get_step('settings').wizard_form_data['prod_config']).to eq(true)
          expect(subject).to_not be_valid
          expect(subject.errors[:push_notification_url]).to include(
            "'localhost' is not allowed on Production",
          )
        end
      end

      describe 'production ready with existing localhost URLs' do
        subject do
          create(:wizard_step, user: first_user, step_name: 'settings', wizard_form_data:    {
            prod_config: true,
          })
          create(:wizard_step, user: first_user, step_name: 'redirects', wizard_form_data: {
            push_notification_url: 'http://localhost:3001/',
            failure_to_proof_url: 'https://localhost:3001',
            redirect_uris: ['https://localhost:3001/somepath'],
          })
        end

        it 'fails when URL is updated but still localhost' do
          subject.current_user_id = user.id
          subject.wizard_form_data = {
            push_notification_url: 'http://localhost:3001/new_url',
            failure_to_proof_url: 'https://localhost:3001',
            redirect_uris: ['https://good.gov'],
          }

          expect(subject.get_step('settings').wizard_form_data['prod_config']).to eq(true)
          expect(subject).to_not be_valid
          expect(subject.errors[:push_notification_url]).to include(
            "'localhost' is not allowed on Production",
          )
          expect(subject.errors).to_not include(:failure_to_proof_url, :redirect_uris)
        end
      end
    end
  end

  describe '.all_step_data_for_user' do
    let(:subject_user) { create(:user) }

    it 'concatenates all the latest steps for a user' do
      created_steps = WizardStep::STEPS.map do |step_name|
        create(:wizard_step, step_name: step_name, user: subject_user)
      end
      ignored_user = create(:user)
      extra_step = create(:wizard_step, step_name: 'issuer', user: ignored_user, wizard_form_data: {
        issuer: 'issuer string that should not appear',
      })

      all_step_data = created_steps.map(&:wizard_form_data).reduce(&:merge)
      expect(WizardStep.all_step_data_for_user(subject_user)).to eq(all_step_data)
      expect(WizardStep.all_step_data_for_user(subject_user).values)
        .to_not include(extra_step.issuer)

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
      expect(WizardStep.all_step_data_for_user(subject_user).keys)
        .to_not include('issuer')
    end

    it 'returns an empty hash when no data has been saved' do
      expect(WizardStep.all_step_data_for_user(subject_user)).to eq({})
    end
  end

  describe '.generate_steps' do
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
      wizard_steps = WizardStep.generate_steps(
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
