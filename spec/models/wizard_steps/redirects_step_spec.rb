require 'rails_helper'
RSpec.describe WizardSteps::RedirectsStep do
  let(:user) { create(:user) }
  let(:redirect_uris) { [] }
  let(:failure_to_proof_url) { '' }
  let(:push_notification_url) { '' }
  let(:acs_url) { '' }
  let(:sp_initiated_login_url) { '' }
  let(:return_to_sp_url) { '' }
  let(:assertion_consumer_logout_service_url) { '' }
  let(:wizard_form_data) do
    {
      redirect_uris:,
      failure_to_proof_url:,
      push_notification_url:,
      acs_url:,
      sp_initiated_login_url:,
      return_to_sp_url:,
      assertion_consumer_logout_service_url:,
    }.as_json
  end
  let(:wizard_step) do
    create(:wizard_step, user:, step_name: 'redirects', wizard_form_data:)
  end

  subject { described_class.new(wizard_step) }

  describe '.fields' do
    it 'returns the expected fields' do
      expect(described_class.fields).to eq(
        {
          acs_url: '',
          assertion_consumer_logout_service_url: '',
          block_encryption: ServiceProvider.block_encryptions.keys.last,
          failure_to_proof_url: '',
          post_idv_follow_up_url: nil,
          push_notification_url: '',
          redirect_uris: [],
          return_to_sp_url: '',
          signed_response_message_requested: true,
          sp_initiated_login_url: '',
        },
      )
    end
  end

  describe '.step_name' do
    it 'returns "redirects"' do
      expect(described_class.step_name).to eq 'redirects'
    end
  end

  describe '#init' do
    it 'sets the wizard_step attribute' do
      expect(subject.instance_variable_get(:@wizard_step)).to eq wizard_step
    end
  end

  describe 'validations' do
    describe 'when all attributes are present and valid' do
      let(:redirect_uris) { ['https://example.gov/callback'] }
      let(:failure_to_proof_url) { 'https://example.gov/failure' }
      let(:push_notification_url) { 'https://example.gov/push' }

      it 'is valid' do
        expect(subject.valid?).to be true
      end
    end

    describe 'redirect_uris' do
      describe 'when redirect_uris contains valid URLs' do
        let(:redirect_uris) { ['https://example.gov/callback', 'https://test.example.gov/auth'] }

        it 'is valid' do
          expect(subject.valid?).to be true
        end
      end

      describe 'when redirect_uris contains an invalid URI' do
        let(:redirect_uris) { ['http//bad-uri'] }

        it 'is not valid' do
          expect(subject.valid?).to be false
          expect(subject.errors[:redirect_uris]).to include(
            "#{redirect_uris[0]} is not a valid URI",
          )
        end
      end

      describe 'when redirect_uris contains a URL with an invalid host' do
        let(:redirect_uris) { ["https://bad'host.gov/callback"] }

        it 'is not valid' do
          expect(subject.valid?).to be false
          expect(subject.errors[:redirect_uris]).to include(
            "#{redirect_uris[0]} has an invalid host",
          )
        end
      end

      describe 'when redirect_uris contains wildcards' do
        let(:redirect_uris) { ['https://*.example.gov/callback'] }

        it 'is not valid' do
          expect(subject.valid?).to be false
          expect(subject.errors[:redirect_uris]).to include(
            "#{redirect_uris[0]} contains invalid wildcards(*)",
          )
        end
      end

      describe 'when redirect_uris is empty' do
        let(:redirect_uris) { [] }

        it 'is valid' do
          expect(subject.valid?).to be true
        end
      end
    end

    describe 'failure_to_proof_url' do
      describe 'when failure_to_proof_url is a valid URL' do
        let(:failure_to_proof_url) { 'https://example.gov/failure' }

        it 'is valid' do
          expect(subject.valid?).to be true
        end
      end

      describe 'when failure_to_proof_url is invalid' do
        let(:failure_to_proof_url) { 'not-a-valid-url' }

        it 'is not valid' do
          expect(subject.valid?).to be false
          expect(subject.errors[:failure_to_proof_url]).to include(
            "#{failure_to_proof_url} is not a valid URI",
          )
        end
      end

      describe 'when failure_to_proof_url contains wildcards' do
        let(:failure_to_proof_url) { 'https://*.example.gov/failure' }

        it 'is not valid' do
          expect(subject.valid?).to be false
          expect(subject.errors[:failure_to_proof_url]).to include(
            "#{failure_to_proof_url} contains invalid wildcards(*)",
          )
        end
      end

      describe 'when failure_to_proof_url is empty' do
        let(:failure_to_proof_url) { '' }

        it 'is valid' do
          expect(subject.valid?).to be true
        end
      end

      describe 'when ial is 2' do
        before do
          create(:wizard_step, user:, step_name: 'authentication', wizard_form_data: {
            ial: 2,
          })
        end
        describe 'when failure_to_proof_url is blank' do
          let(:failure_to_proof_url) { '' }

          it 'is not valid' do
            expect(subject.valid?).to be false
            expect(subject.errors[:failure_to_proof_url]).to include("can't be empty")
          end
        end

        describe 'when failure_to_proof is present' do
          let(:failure_to_proof_url) { 'https://example.gov/failure' }

          it 'is valid' do
            expect(subject.valid?).to be true
          end
        end
      end
    end

    describe 'push_notification_url' do
      describe 'when push_notification_url is a valid URL' do
        let(:push_notification_url) { 'https://example.gov/push' }

        it 'is valid' do
          expect(subject.valid?).to be true
        end
      end

      describe 'when push_notification_url is invalid' do
        let(:push_notification_url) { 'bad-url' }

        it 'is not valid' do
          expect(subject.valid?).to be false
          expect(subject.errors[:push_notification_url]).to include(
            "#{push_notification_url} is not a valid URI",
          )
        end
      end

      describe 'when push_notification_url contains wildcards' do
        let(:push_notification_url) { 'https://*.example.gov/push' }

        it 'is not valid' do
          expect(subject.valid?).to be false
          expect(subject.errors[:push_notification_url]).to include(
            "#{push_notification_url} contains invalid wildcards(*)",
          )
        end
      end

      describe 'when push_notification_url has an invalid host' do
        let(:push_notification_url) { "http://local'host:0" }

        it 'is not valid' do
          expect(subject.valid?).to be false
          expect(subject.errors[:push_notification_url]).to include(
            "#{push_notification_url} has an invalid host",
          )
        end
      end
    end

    describe 'acs_url' do
      describe 'when acs_url is a valid URL' do
        let(:acs_url) { 'https://example.gov/saml/acs' }

        it 'is valid' do
          expect(subject.valid?).to be true
        end
      end

      describe 'when acs_url is invalid' do
        let(:acs_url) { 'not_a_url' }

        it 'is not valid' do
          expect(subject.valid?).to be false
          expect(subject.errors[:acs_url]).to include("#{acs_url} is not a valid URI")
        end
      end

      describe 'when acs_url contains wildcards' do
        let(:acs_url) { 'https://*.example.gov/saml/acs' }

        it 'is not valid' do
          expect(subject.valid?).to be false
          expect(subject.errors[:acs_url]).to include(
            "#{acs_url} contains invalid wildcards(*)",
          )
        end
      end
    end

    describe 'sp_initiated_login_url' do
      describe 'when sp_initiated_login_url is a valid URL' do
        let(:sp_initiated_login_url) { 'https://example.gov/saml/login' }

        it 'is valid' do
          expect(subject.valid?).to be true
        end
      end

      describe 'when sp_initiated_login_url is invalid' do
        let(:sp_initiated_login_url) { 'invalid' }

        it 'is not valid' do
          expect(subject.valid?).to be false
          expect(subject.errors[:sp_initiated_login_url]).to include(
            "#{sp_initiated_login_url} is not a valid URI",
          )
        end
      end

      describe 'when sp_initiated_login_url contains wildcards' do
        let(:sp_initiated_login_url) { 'https://*.example.gov/saml/login' }

        it 'is not valid' do
          expect(subject.valid?).to be false
          expect(subject.errors[:sp_initiated_login_url]).to include(
            "#{sp_initiated_login_url} contains invalid wildcards(*)",
          )
        end
      end
    end

    describe 'return_to_sp_url' do
      describe 'when return_to_sp_url is a valid URL' do
        let(:return_to_sp_url) { 'https://example.gov/return' }

        it 'is valid' do
          expect(subject.valid?).to be true
        end
      end

      describe 'when return_to_sp_url is invalid' do
        let(:return_to_sp_url) { 'bad' }

        it 'is not valid' do
          expect(subject.valid?).to be false
          expect(subject.errors[:return_to_sp_url]).to include(
            "#{return_to_sp_url} is not a valid URI",
          )
        end
      end

      describe 'when return_to_sp_url contains wildcards' do
        let(:return_to_sp_url) { 'https://*.example.gov/return' }

        it 'is not valid' do
          expect(subject.valid?).to be false
          expect(subject.errors[:return_to_sp_url]).to include(
            "#{return_to_sp_url} contains invalid wildcards(*)",
          )
        end
      end
    end

    describe 'assertion_consumer_logout_service_url' do
      describe 'when assertion_consumer_logout_service_url is a valid URL' do
        let(:assertion_consumer_logout_service_url) { 'https://example.gov/logout' }

        it 'is valid' do
          expect(subject.valid?).to be true
        end
      end

      describe 'when assertion_consumer_logout_service_url is invalid' do
        let(:assertion_consumer_logout_service_url) { 'invalid-url' }

        it 'is not valid' do
          expect(subject.valid?).to be false
          expect(subject.errors[:assertion_consumer_logout_service_url]).to include(
            "#{assertion_consumer_logout_service_url} is not a valid URI",
          )
        end
      end

      describe 'when assertion_consumer_logout_service_url contains wildcards' do
        let(:assertion_consumer_logout_service_url) { 'https://*.example.gov/logout' }

        it 'is not valid' do
          expect(subject.valid?).to be false
          expect(subject.errors[:assertion_consumer_logout_service_url]).to include(
            "#{assertion_consumer_logout_service_url} contains invalid wildcards(*)",
          )
        end
      end
    end

    describe 'localhost restrictions on production configs' do
      let(:admin_user) { create(:user, :logingov_admin) }

      before do
        create(:wizard_step, user:, step_name: 'settings', wizard_form_data: {
          prod_config: true,
        })
      end

      describe 'when a logingov_admin uses localhost URLs' do
        let(:user) { admin_user }

        it 'is valid' do
          wizard_step.wizard_form_data = wizard_step.wizard_form_data.merge(
            push_notification_url: 'http://localhost:3000/changed',
          )
          changed_subject = described_class.new(wizard_step)
          expect(changed_subject.valid?).to be true
        end
      end

      describe 'when a non-admin user tries to add localhost URLs on prod config' do
        before do
          wizard_step.wizard_form_data = {
            push_notification_url: 'http://localhost:3000/original',
          }
          wizard_step.current_user_id = user.id
          wizard_step.save!
        end

        it 'is not valid' do
          wizard_step.wizard_form_data = wizard_step.wizard_form_data.merge(
            push_notification_url: 'http://localhost:3000/changed',
          )
          changed_subject = described_class.new(wizard_step)

          expect(changed_subject.valid?).to be false
          expect(changed_subject.errors[:push_notification_url]).to include(
            "'localhost' is not allowed on Production",
          )
        end
      end

      describe 'when localhost URLs exist but are unchanged' do
        let(:push_notification_url) { 'http://localhost:3000/push' }

        it 'is valid when unchanged' do
          wizard_step.current_user_id = user.id
          wizard_step.save!

          # Create a new step object from the reloaded wizard_step
          reloaded_step = WizardStep.find(wizard_step.id)
          reloaded_step.current_user_id = user.id
          reloaded_subject = described_class.new(reloaded_step)

          expect(reloaded_subject.valid?).to be true
        end
      end

      describe 'when a non-admin changes a localhost URL to another localhost URL' do
        before do
          wizard_step.wizard_form_data = {
            push_notification_url: 'http://localhost:3000/original',
          }
          wizard_step.current_user_id = user.id
          wizard_step.save!
        end
        it 'is not valid' do
          wizard_step.wizard_form_data = wizard_step.wizard_form_data.merge(
            push_notification_url: 'http://localhost:3000/changed',
          )
          changed_subject = described_class.new(wizard_step)

          expect(changed_subject.valid?).to be false
          expect(changed_subject.errors[:push_notification_url]).to include(
            "'localhost' is not allowed on Production",
          )
        end
      end

      describe 'when 127.0.0.1 is used instead of localhost' do
        before do
          wizard_step.wizard_form_data = {
            push_notification_url: 'http://localhost:3000/original',
          }
          wizard_step.current_user_id = user.id
          wizard_step.save!
        end

        it 'is not valid' do
          wizard_step.wizard_form_data = wizard_step.wizard_form_data.merge(
            push_notification_url: 'http://127.0.0.1:3000/changed',
          )
          changed_subject = described_class.new(wizard_step)

          expect(changed_subject.valid?).to be false
          expect(changed_subject.errors[:push_notification_url]).to include(
            "'localhost' is not allowed on Production",
          )
        end
      end
    end

    describe 'saml_settings_present' do
      describe 'when protocol is not SAML' do
        before do
          create(:wizard_step, user:, step_name: 'protocol', wizard_form_data: {
            identity_protocol: 'openid_connect_private_key_jwt',
          })
        end

        describe 'when acs_url and return_to_sp_url are blank' do
          let(:acs_url) { '' }
          let(:return_to_sp_url) { '' }

          it 'is valid' do
            expect(subject.valid?).to be true
          end
        end
      end

      describe 'when protocol is SAML' do
        before do
          create(:wizard_step, user:, step_name: 'protocol', wizard_form_data: {
            identity_protocol: 'saml',
          })
        end

        describe 'when both acs_url and return_to_sp_url are present' do
          let(:acs_url) { 'https://example.gov/saml/acs' }
          let(:return_to_sp_url) { 'https://example.gov/return' }

          it 'is valid' do
            expect(subject.valid?).to be true
          end
        end

        describe 'when acs_url is blank' do
          let(:acs_url) { '' }
          let(:return_to_sp_url) { 'https://example.gov/return' }

          it 'is not valid' do
            expect(subject.valid?).to be false
            expect(subject.errors[:acs_url]).to include(" can't be blank")
          end
        end

        describe 'when return_to_sp_url is blank' do
          let(:acs_url) { 'https://example.gov/saml/acs' }
          let(:return_to_sp_url) { '' }

          it 'is not valid' do
            expect(subject.valid?).to be false
            expect(subject.errors[:return_to_sp_url]).to include(" can't be blank")
          end
        end

        describe 'when both acs_url and return_to_sp_url are blank' do
          let(:acs_url) { '' }
          let(:return_to_sp_url) { '' }

          it 'is not valid' do
            expect(subject.valid?).to be false
            expect(subject.errors[:acs_url]).to include(" can't be blank")
            expect(subject.errors[:return_to_sp_url]).to include(" can't be blank")
          end
        end

        describe 'when acs_url is nil' do
          let(:acs_url) { nil }
          let(:return_to_sp_url) { 'https://example.gov/return' }

          it 'is not valid' do
            expect(subject.valid?).to be false
            expect(subject.errors[:acs_url]).to include(" can't be blank")
          end
        end

        describe 'when return_to_sp_url is nil' do
          let(:acs_url) { 'https://example.gov/saml/acs' }
          let(:return_to_sp_url) { nil }

          it 'is not valid' do
            expect(subject.valid?).to be false
            expect(subject.errors[:return_to_sp_url]).to include(" can't be blank")
          end
        end
      end
    end

    describe 'multiple URL validation errors' do
      let(:redirect_uris) { ['http//bad'] }
      let(:push_notification_url) { 'not-valid' }
      let(:failure_to_proof_url) { 'also-bad' }

      it 'accumulates errors for all invalid URLs' do
        expect(subject.valid?).to be false
        expect(subject.errors[:redirect_uris]).to_not be_empty
        expect(subject.errors[:push_notification_url]).to_not be_empty
        expect(subject.errors[:failure_to_proof_url]).to_not be_empty
      end
    end
  end
end
