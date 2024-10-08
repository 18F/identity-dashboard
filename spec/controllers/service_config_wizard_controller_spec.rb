require 'rails_helper'

RSpec.describe ServiceConfigWizardController do
  let(:user) { create(:user, uuid: SecureRandom.uuid, admin: false) }
  let(:admin) { create(:user, :with_teams, uuid: SecureRandom.uuid, admin: true) }
  let(:agency) { create(:agency, name: 'GSA') }
  let(:team) { create(:team, agency: agency) }
  let(:fixture_path) { File.expand_path('../fixtures/files', __dir__) }
  let(:logo_file_params) {
    Rack::Test::UploadedFile.new(
      File.open(fixture_path + '/logo.svg'),
      'image/svg+xml',
      true,
      original_filename: 'alternative_filename.svg',
    )
  }

  def flag_in
    expect(IdentityConfig.store).to receive(:service_config_wizard_enabled).and_return(true)
  end

  def flag_out
    expect(IdentityConfig.store).to receive(:service_config_wizard_enabled).and_return(false)
  end

  def step_index(step_name)
    ServiceConfigWizardController::STEPS.index(step_name)
  end

  context 'as an admin' do
    before do
      sign_in admin
    end

    it 'can get all steps' do
      ServiceConfigWizardController::STEPS.each do |wizard_step|
        get :show, params: {id: wizard_step}
        expect(response).to be_ok
        expect(assigns[:model].step_name).to eq(wizard_step)
      end
    end

    it 'will wipe all step data if the user cancels on the last step' do
      create(:wizard_step, user: admin, data: { help_text: {'sign_in' => 'blank'}})
      expect do
        put :update, params: {id: ServiceConfigWizardController::STEPS.last, commit: 'Cancel'}
      end.to(change {WizardStep.count}.by(-1))
      expect(response.redirect_url).to eq(service_providers_url)
    end

    describe '#new' do
      it 'can start the first step' do
        flag_in
        get :new
        expect(response).to be_redirect
        expect(response.redirect_url).to eq(service_config_wizard_url(Wicked::FIRST_STEP))
      end

      it 'will be redirected if the flag is not set' do
        flag_out
        get :new
        expect(response).to be_redirect
        expect(response.redirect_url).to eq(service_providers_url)
      end
    end

    it 'will persist SAML options when editing an OIDC config' do
      saml_app_config = create(:service_provider, :ready_to_activate, :saml)
      # The `#reload` is here because I _think_ our CI env database has slightly less
      # timestamp precision our dev envs and Ruby itself. By making sure we're always pulling
      # time attributes from the database before comparing them, we avoid rounding errors that would
      # otherwise make this a flaky test.
      initial_attributes = saml_app_config.reload.attributes

      put :create, params: { service_provider: saml_app_config.id }
      put :update, params: {id: 'authentication', wizard_step: {
        identity_protocol: 'openid_connect_pkce',
        ial: saml_app_config.ial,
        default_aal: saml_app_config.default_aal,
        attribute_bundle: saml_app_config.attribute_bundle,
      }}
      last_step = WizardStep.find_by(step_name: WizardStep::STEPS.last, user: admin)
      put :update, params: {id: last_step.step_name, wizard_step: last_step.data }

      new_attributes = saml_app_config.reload.attributes
      expect(new_attributes['updated_at']).to be >= initial_attributes['updated_at']
      # Now that we've asserted them, discard them and keep testing
      new_attributes.delete 'updated_at'
      initial_attributes.delete 'updated_at'

      # I think we don't distinguish between nil or empty list for this attribute
      if [nil, []].include? initial_attributes['redirect_uris']
        expect(new_attributes['redirect_uris']).to be_in([nil, []])
        new_attributes.delete 'redirect_uris'
        initial_attributes.delete 'redirect_uris'
      end

      expect(new_attributes).to_not eq(initial_attributes)
      initial_attributes.delete('identity_protocol')
      new_attributes.delete('identity_protocol')

      expect(new_attributes).to eq(initial_attributes)
    end

    describe 'step "settings"' do
      it 'can post' do
        expect do
          put :update, params: {id: 'settings', wizard_step: {
            app_name: "App name #{rand(1..1000)}",
            friendly_name: "Friendly name name #{rand(1..1000)}",
            group_id: create(:team).id,
          }}
          expect(response).to be_redirect,
            "Not redirected to next step. Errors found: #{assigns['model'].errors.messages}"
        end.to(change {WizardStep.count}.by(1))
        next_step = ServiceConfigWizardController::STEPS[step_index('settings') + 1]
        expect(response.redirect_url).to eq(service_config_wizard_url(next_step)) if next_step
      end
    end
 
    describe 'step "authentication"' do
      it 'can post' do
        expect do
          put :update, params: {id: 'authentication', wizard_step: {
            identity_protocol: 'openid_connect_private_key_jwt',
            ial: '1',
            # Rails forms regularly put an initial, hidden, and blank entry for various inputs
            attribute_bundle: ['', 'email'],
          }}
          expect(response).to be_redirect,
            "Not redirected to next step. Errors found: #{assigns['model'].errors.messages}"
        end.to(change {WizardStep.count}.by(1))
        next_step = ServiceConfigWizardController::STEPS[step_index('authentication') + 1]
        expect(response.redirect_url).to eq(service_config_wizard_url(next_step))
      end

      it 'sets attribute bundle errors' do
        expect do
          put :update, params: {id: 'authentication', wizard_step: {
            identity_protocol: 'saml',
            ial: '2',
            attribute_bundle: [],
          }}
        end.to_not(change {WizardStep.count})
        expect(response).to_not be_redirect
        expect(assigns[:model].errors.messages.keys).to eq([:attribute_bundle])
        actual_error = assigns[:model].errors[:attribute_bundle].to_sentence
        expect(actual_error).to eq('Attribute bundle cannot be empty')
      end
    end

    describe 'step "issuer"' do
      it 'can post' do
        expect do
          put :update, params: {id: 'issuer', wizard_step: {issuer: "test:sso:#{rand(1..1000)}"}}
          expect(response).to be_redirect,
            "Not redirected to next step. Errors found: #{assigns['model'].errors.messages}"
        end.to(change {WizardStep.count}.by(1))
        next_step = ServiceConfigWizardController::STEPS[step_index('issuer') + 1]
        expect(response.redirect_url).to eq(service_config_wizard_url(next_step))
      end
    end

    describe 'step "logo_and_cert"' do
      it 'allows blank info' do
        expect do
          put :update, params: {id: 'logo_and_cert'}
          expect(response).to be_redirect,
            "Not redirected to next step. Errors found: #{assigns['model'].errors.messages}"
        end.to(change {WizardStep.count}.by(1))
        next_index = ServiceConfigWizardController::STEPS.index('logo_and_cert') + 1
        next_step = ServiceConfigWizardController::STEPS[next_index]
        expect(response.redirect_url).to eq(service_config_wizard_url(next_step))
      end

      it 'can post new data' do
        test_cert = fixture_file_upload('testcert.pem')
        test_logo = fixture_file_upload('logo.svg', 'image/svg+xml')
        expect do
          put :update, params: {id: 'logo_and_cert', wizard_step: {
            logo_file: test_logo,
            cert: test_cert,
          }}
          expect(response).to be_redirect,
            "Not redirected to next step. Errors found: #{assigns['model'].errors.messages}"
        end.to(change {WizardStep.count}.by(1))
        next_step = ServiceConfigWizardController::STEPS[step_index('logo_and_cert') + 1]
        expect(response.redirect_url).to eq(service_config_wizard_url(next_step))
        expect(WizardStep.last.certs).to eq([test_cert.read])
        expect(WizardStep.last.logo_file.download).to eq(test_logo.read)
      end

      it 'will skip an empty cert' do
        empty_upload = Rack::Test::UploadedFile.new(
          StringIO.new(''),
          original_filename: 'empty.pem',
        )
        expect do
          put :update, params: {id: 'logo_and_cert', wizard_step: {
            cert: empty_upload,
          }}
        end.to(change {WizardStep.count}.by(1))
        expect(response).to be_redirect
        expect(WizardStep.last.certs).to eq([])
      end

      it 'can overwrite existing data' do
        first_upload_logo = fixture_file_upload('logo.svg', 'image/svg+xml')
        put :update, params: {id: 'logo_and_cert', wizard_step: {
          logo_file: first_upload_logo,
          cert: fixture_file_upload('testcert.pem', 'text/plain'),
        }}
        original_settings = WizardStep.last
        original_certs = original_settings.certs
        original_serial = OpenSSL::X509::Certificate.new(original_certs.first).serial
        original_saved_logo = original_settings.logo_file
        expect(original_saved_logo.blob.checksum).
          to eq(OpenSSL::Digest.base64digest('MD5', first_upload_logo.read))
        

        # Deliberately picking a serial that's shorter than fixed value of the original serial
        new_serial = rand(1..100_000)
        new_cert = Rack::Test::UploadedFile.new(
          StringIO.new(build_pem(serial: new_serial)),
          original_filename: 'new_cert.pem',
        )
        new_logo_upload = fixture_file_upload('logo.png', 'image/png')
        expect do
          put :update, params: {id: 'logo_and_cert', wizard_step: {
            logo_file: new_logo_upload,
            remove_certificates: [original_serial],
            cert: new_cert,
          }}
        end.to_not(change {WizardStep.count})

        expect(response).to be_redirect
        next_step = ServiceConfigWizardController::STEPS[step_index('logo_and_cert') + 1]
        expect(response.redirect_url).to eq(service_config_wizard_url(next_step))

        new_settings = WizardStep.last
        expect(new_settings.certs.count).to be(original_certs.count)
        expect(new_settings.certs.count).to be(1)
        new_cert = OpenSSL::X509::Certificate.new(new_settings.certs.first)
        expect(new_cert.serial).to eq(new_serial)
        expect(new_cert.serial).to_not eq(original_serial)

        expect(new_settings.logo_file.blob.checksum).to_not eq(original_saved_logo.blob.checksum)
        expect(new_settings.logo_file.blob.checksum).
          to eq(OpenSSL::Digest.base64digest('MD5', new_logo_upload.read))
      end

      it 'sets errors for bad SVGs' do
        expect do
          put :update, params: {id: 'logo_and_cert', wizard_step: {
            logo_file: fixture_file_upload('../logo_with_script.svg'),
          }}
        end.to_not(change {WizardStep.count})
        expect(response).to_not be_redirect
        actual_error = assigns[:model].errors[:logo_file].to_sentence
        expected_error = I18n.t(
          'service_provider_form.errors.logo_file.has_script_tag',
          filename: 'logo_with_script.svg',
        )
        expect(actual_error).to eq(expected_error)
      end

      it 'keeps an existing logo if a new logo is bad' do
        good_logo_upload = fixture_file_upload('logo.svg')
        good_logo_checksum = OpenSSL::Digest.base64digest('MD5', good_logo_upload.read)
        bad_logo_upload = fixture_file_upload('../logo_without_size.svg')
        put :update, params: {id: 'logo_and_cert', wizard_step: {
          logo_file: good_logo_upload,
        }}
        saved_step = WizardStep.last
        expect(saved_step.logo_file.blob.checksum).to eq(good_logo_checksum)

        put :update, params: {id: 'logo_and_cert', wizard_step: {
          logo_file: bad_logo_upload,
        }}
        expect(response).to_not be_redirect
        actual_error = assigns[:model].errors[:logo_file].to_sentence
        expected_error = I18n.t(
          'service_provider_form.errors.logo_file.no_viewbox',
          filename: 'logo_without_size.svg',
        )
        expect(actual_error).to eq(expected_error)
        saved_step.reload
        saved_step.logo_file.reload
        expect(saved_step.logo_file.blob.checksum).to eq(good_logo_checksum)
      end
    end

    describe 'step "redirects"' do
      it 'can post' do
        expect do
          put :update, params: {id: 'redirects', wizard_step: {active: false}}
          expect(response).to be_redirect,
            "Not redirected to next step. Errors found: #{assigns['model'].errors.messages}"
        end.to(change {WizardStep.count}.by(1))
        next_step = ServiceConfigWizardController::STEPS[step_index('redirects') + 1]
        expect(response.redirect_url).to eq(service_config_wizard_url(next_step))
      end
    end

    # help_text gets saved to draft, then to `service_provider`, then deleted in one step
    describe 'step "help_text"' do
      it 'can post' do
        pending
        expect do
          put :update, params: {id: 'help_text', wizard_step: {active: false}}
          expect(response).to be_redirect,
            "Not redirected to next step. Errors found: #{assigns['model'].errors.messages}"
        end.to(change {WizardStep.count}.by(1))
        next_step = ServiceConfigWizardController::STEPS[step_index('help_text') + 1]
        if next_step
          expect(response.redirect_url).to eq(service_config_wizard_url(next_step))
        end        
      end
    end

    it 'returns to list of apps if nothing is saved' do
      put :update, params: {id: 'help_text', commit: 'cancel'}
      expect(response).to be_redirect
      expect(response.redirect_url).to eq(service_providers_url)
    end
  end

  context 'as a non-admin user' do
    before do
      sign_in user
    end

    it 'can start the first step' do
      flag_in
      get :new
      expect(response).to be_redirect
      expect(response.redirect_url).to eq(service_config_wizard_url(Wicked::FIRST_STEP))
    end

    it 'will be redirected if the flag is not set' do
      flag_out
      get :new
      expect(response).to be_redirect
      expect(response.redirect_url).to eq(service_providers_url)
    end

    describe 'logo and cert' do
      it 'adds new certs uploaded to the certs array' do
        file = Rack::Test::UploadedFile.new(
                 StringIO.new(build_pem(serial: 10)),
                 original_filename: 'my-cert.crt',
               )

        put :update,
          params: {
            id: 'logo_and_cert',
            wizard_step: { cert: file},
          }
        logo_and_cert_step = WizardStep.where(step_name: 'logo_and_cert').last
        has_serial = logo_and_cert_step.certificates.any? { |c| c.serial.to_s == '10' }
        expect(has_serial).to eq(true)
      end
    end
  end

  context 'when not logged in' do
    it 'requires authentication without checking flag status' do
      expect(IdentityConfig.store).to receive(:service_config_wizard_enabled).never
      get :new
      expect(response).to be_redirect
      expect(response.redirect_url).to eq(root_url)
    end
  end
end
