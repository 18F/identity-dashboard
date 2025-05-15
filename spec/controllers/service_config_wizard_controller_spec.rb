require 'rails_helper'

RSpec.describe ServiceConfigWizardController do
  let(:team) { create(:team, agency:) }
  let(:partner_admin) do
    user = create(:user, uuid: SecureRandom.uuid, admin: false)
    create(:user_team, :partner_admin, user:, team:)
    user
  end
  let(:logingov_admin) { create(:user, :logingov_admin) }
  let(:agency) { create(:agency, name: 'GSA') }
  let(:fixture_path) { File.expand_path('../fixtures/files', __dir__) }
  let(:logo_file_params) do
    Rack::Test::UploadedFile.new(
      File.open(fixture_path + '/logo.svg'),
      'image/svg+xml',
      true,
      original_filename: 'alternative_filename.svg',
    )
  end

  def flag_in
    expect(IdentityConfig.store).to receive(:service_config_wizard_enabled).and_return(true)
  end

  def flag_out
    expect(IdentityConfig.store).to receive(:service_config_wizard_enabled).and_return(false)
  end

  def step_index(step_name)
    ServiceConfigWizardController::STEPS.index(step_name)
  end

  context 'as an login.gov admin' do
    let(:wizard_steps_ready_to_go) do
      # The team needs to be persisted and with an ID or WizardStep validation will fail,
      # so it's factory is called here with `create`.
      #
      # The service provider factory used is here because it has good defaults — it should
      # be the authoritative factory for what we need in a service provider. By calling that factory
      # with `build``, we get its defaults without saving it to the database. Done this way, we can
      # test that the controller can create a reasonable service_provider that isn't already saved.
      WizardStep.steps_from_service_provider(
        build(:service_provider, :ready_to_activate, team:),
        logingov_admin,
      )
    end

    before do
      sign_in logingov_admin
    end

    it 'can get all steps' do
      ServiceConfigWizardController::STEPS.each do |wizard_step|
        get :show, params: { id: wizard_step }
        expect(response).to be_ok
        expect(assigns[:model].step_name).to eq(wizard_step)
      end
    end

    it 'will wipe all step data if the user cancels on the last step' do
      create(:wizard_step,
             user: logingov_admin,
             wizard_form_data: { help_text: { 'sign_in' => 'blank' } })
      expect do
        put :update, params: { id: ServiceConfigWizardController::STEPS.last, commit: 'Cancel' }
      end.to(change { WizardStep.count }.by(-1))
      expect(response.redirect_url).to eq(service_providers_url)
    end

    describe '#new' do
      it 'can start the first step' do
        flag_in
        get :new
        expect(response).to be_redirect
        expect(response.redirect_url).to eq(service_config_wizard_url(Wicked::FIRST_STEP))
      end

      it 'is redirected if the flag is not set' do
        flag_out
        get :new
        expect(response).to be_redirect
        expect(response.redirect_url).to eq(service_providers_url)
      end
    end

    it 'persists SAML options when editing an OIDC config' do
      saml_app_config = create(:service_provider, :ready_to_activate, :saml)
      # The `#reload` is here because I _think_ our CI env database has slightly less
      # timestamp precision our dev envs and Ruby itself. By making sure we're always pulling
      # time attributes from the database before comparing them, we avoid rounding errors that would
      # otherwise make this a flaky test.
      initial_attributes = saml_app_config.reload.attributes

      put :create, params: { service_provider: saml_app_config.id }
      put :update, params: { id: 'protocol', wizard_step: {
        identity_protocol: 'openid_connect_pkce',
      } }
      put :update, params: { id: 'authentication', wizard_step: {
        ial: saml_app_config.ial,
        default_aal: saml_app_config.default_aal,
        attribute_bundle: saml_app_config.attribute_bundle,
      } }
      last_step = WizardStep.find_by(step_name: WizardStep::STEPS.last, user: logingov_admin)
      put :update, params: { id: last_step.step_name, wizard_step: last_step.wizard_form_data }

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
          put :update, params: { id: 'settings', wizard_step: {
            app_name: "App name #{rand(1..1000)}",
            friendly_name: "Friendly name name #{rand(1..1000)}",
            group_id: create(:team).id,
          } }
          expect(response).to be_redirect,
            "Not redirected to next step. Errors found: #{assigns['model'].errors.messages}"
        end.to(change { WizardStep.count }.by(1))
        next_step = ServiceConfigWizardController::STEPS[step_index('settings') + 1]
        expect(response.redirect_url).to eq(service_config_wizard_url(next_step)) if next_step
      end
    end

    describe 'step "authentication"' do
      it 'can post' do
        expect do
          put :update, params: { id: 'authentication', wizard_step: {
            ial: '1',
            # Rails forms regularly put an initial, hidden, and blank entry for various inputs
            attribute_bundle: ['', 'email'],
          } }
          expect(response).to be_redirect,
            "Not redirected to next step. Errors found: #{assigns['model'].errors.messages}"
        end.to(change { WizardStep.count }.by(1))
        next_step = ServiceConfigWizardController::STEPS[step_index('authentication') + 1]
        expect(response.redirect_url).to eq(service_config_wizard_url(next_step))
      end

      it 'sets attribute bundle errors' do
        expect do
          put :update, params: { id: 'protocol', wizard_step: {
            identity_protocol: 'saml',
          } }
          put :update, params: { id: 'authentication', wizard_step: {
            ial: '2',
            attribute_bundle: [],
          } }
        end.to(change { WizardStep.count }.by(1))
        expect(response).to_not be_redirect
        expect(assigns[:model].errors.messages.keys).to eq([:attribute_bundle])
        actual_error = assigns[:model].errors[:attribute_bundle].to_sentence
        expect(actual_error).to eq('Attribute bundle cannot be empty')
      end
    end

    describe 'step "issuer"' do
      it 'can post' do
        expect do
          put :update, params: {
            id: 'issuer',
            wizard_step: { issuer: "test:sso:#{rand(1..1000)}" },
          }
          expect(response).to be_redirect,
            "Not redirected to next step. Errors found: #{assigns['model'].errors.messages}"
        end.to(change { WizardStep.count }.by(1))
        next_step = ServiceConfigWizardController::STEPS[step_index('issuer') + 1]
        expect(response.redirect_url).to eq(service_config_wizard_url(next_step))
      end
    end

    describe 'step "logo_and_cert"' do
      let(:good_logo) { fixture_file_upload('logo.svg', 'image/svg+xml') }
      let(:good_cert) { fixture_file_upload('testcert.pem') }

      it 'allows blank info' do
        expect do
          put :update, params: { id: 'logo_and_cert' }
          expect(response).to be_redirect,
            "Not redirected to next step. Errors found: #{assigns['model'].errors.messages}"
        end.to(change { WizardStep.count }.by(1))
        next_index = ServiceConfigWizardController::STEPS.index('logo_and_cert') + 1
        next_step = ServiceConfigWizardController::STEPS[next_index]
        expect(response.redirect_url).to eq(service_config_wizard_url(next_step))
      end

      it 'can post new wizard_form_data' do
        expect do
          put :update, params: { id: 'logo_and_cert', wizard_step: {
            logo_file: good_logo,
            cert: good_cert,
          } }
          expect(response).to be_redirect,
            "Not redirected to next step. Errors found: #{assigns['model'].errors.messages}"
        end.to(change { WizardStep.count }.by(1))
        next_step = ServiceConfigWizardController::STEPS[step_index('logo_and_cert') + 1]
        expect(response.redirect_url).to eq(service_config_wizard_url(next_step))
        expect(WizardStep.last.certs).to eq([good_cert.read])
        expect(WizardStep.last.logo_file.download).to eq(good_logo.read)
      end

      it 'skips an empty cert' do
        empty_upload = Rack::Test::UploadedFile.new(
          StringIO.new(''),
          original_filename: 'empty.pem',
        )
        expect do
          put :update, params: { id: 'logo_and_cert', wizard_step: {
            cert: empty_upload,
          } }
        end.to(change { WizardStep.count }.by(1))
        expect(response).to be_redirect
        expect(WizardStep.last.certs).to eq([])
      end

      it 'can overwrite existing wizard_form_data' do
        put :update, params: { id: 'logo_and_cert', wizard_step: {
          logo_file: good_logo,
          cert: good_cert,
        } }
        original_settings = WizardStep.last
        original_certs = original_settings.certs
        original_serial = OpenSSL::X509::Certificate.new(original_certs.first).serial
        original_saved_logo = original_settings.logo_file
        expect(original_saved_logo.blob.checksum).
          to eq(OpenSSL::Digest.base64digest('MD5', good_logo.read))

        # Deliberately picking a serial that's shorter than fixed value of the original serial
        new_serial = rand(1..100_000)
        new_cert = Rack::Test::UploadedFile.new(
          StringIO.new(build_pem(serial: new_serial)),
          original_filename: 'new_cert.pem',
        )
        new_logo_upload = fixture_file_upload('logo.png', 'image/png')
        expect do
          put :update, params: { id: 'logo_and_cert', wizard_step: {
            logo_file: new_logo_upload,
            remove_certificates: [original_serial],
            cert: new_cert,
          } }
        end.to_not(change { WizardStep.count })

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
          put :update, params: { id: 'logo_and_cert', wizard_step: {
            logo_file: fixture_file_upload('../logo_with_script.svg'),
          } }
        end.to_not(change { WizardStep.count })
        expect(response).to_not be_redirect
        actual_error = assigns[:model].errors[:logo_file].to_sentence
        expected_error = I18n.t(
          'service_provider_form.errors.logo_file.has_script_tag',
          filename: 'logo_with_script.svg',
        )
        expect(actual_error).to eq(expected_error)
      end

      it 'keeps an existing logo if a new logo is bad' do
        good_logo_checksum = OpenSSL::Digest.base64digest('MD5', good_logo.read)
        bad_logo_upload = fixture_file_upload('../logo_without_size.svg')
        put :update, params: { id: 'logo_and_cert', wizard_step: {
          logo_file: good_logo,
        } }
        saved_step = WizardStep.last
        expect(saved_step.logo_file.blob.checksum).to eq(good_logo_checksum)

        put :update, params: { id: 'logo_and_cert', wizard_step: {
          logo_file: bad_logo_upload,
        } }
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

      it 'can move a valid logo from the wizard step to a service provider' do
        wizard_steps_ready_to_go.each(&:save!)
        logo_step = wizard_steps_ready_to_go.find { |ws| ws.step_name == 'logo_and_cert' }
        expect(logo_step.logo_file).to be_blank
        put :update, params: { id: 'logo_and_cert', wizard_step: { logo_file: good_logo } }
        expect do
          put :update, params: { id: 'help_text', wizard_step: { active: false } }
        end.to(change { ServiceProvider.count }.by(1))
        expect(ServiceProvider.last.logo_file.download).to eq(good_logo.read)
      end
    end

    describe 'step "redirects"' do
      it 'can post' do
        expect do
          put :update, params: { id: 'redirects', wizard_step: { active: false } }
          expect(response).to be_redirect,
            "Not redirected to next step. Errors found: #{assigns['model'].errors.messages}"
        end.to(change { WizardStep.count }.by(1))
        next_step = ServiceConfigWizardController::STEPS[step_index('redirects') + 1]
        expect(response.redirect_url).to eq(service_config_wizard_url(next_step))
      end
    end

    # help_text gets saved to draft, then to `service_provider`, then deleted in one step
    describe 'step "help_text"' do
      it 'can save valid service provider settings' do
        wizard_steps_ready_to_go.each(&:save!)
        expect do
          put :update, params: { id: 'help_text', wizard_step: { active: false } }
          error_messages = assigns['model'].errors.messages.merge(
            assigns['service_provider'].errors.messages,
          )
          expect(response).to be_redirect,
            "Not redirected to next step. Errors found: #{error_messages}"
        end.to(change { ServiceProvider.count }.by(1))
        expect(response.redirect_url).to eq(service_provider_url(ServiceProvider.last))
        expect(assigns['service_provider']).to eq(ServiceProvider.last)
        expect(WizardStep.where(user: logingov_admin)).to be_empty
      end

      it 'stays on this step when the service provider would be invalid' do
        expect do
          put :update, params: { id: 'help_text', wizard_step: { active: false } }
        end.not_to(change { ServiceProvider.count })
        error_messages = assigns['model'].errors.messages.merge(
          assigns['service_provider'].errors.messages,
        )
        expect(error_messages.count).to be >= 1
      end
    end

    it 'returns to list of apps if nothing is saved' do
      put :update, params: { id: 'help_text', commit: 'cancel' }
      expect(response).to be_redirect
      expect(response.redirect_url).to eq(service_providers_url)
    end

    describe 'handling service provider logos' do
      let(:existing_service_provider) { create(:service_provider, :with_team) }
      let(:good_upload) { fixture_file_upload('logo.svg') }
      let(:good_upload_checksum) { OpenSSL::Digest.base64digest('MD5', good_upload.read) }

      scenario 'adding a logo to a config' do
        put :create, params: { service_provider: existing_service_provider }
        expect(existing_service_provider.logo_file).to_not be_attached
        put :update, params: { id: 'logo_and_cert', wizard_step: {
          logo_file: good_upload,
        } }
        default_help_text_data = build(:wizard_step, step_name: 'help_text').wizard_form_data
        put :update, params: { id: 'help_text', wizard_step: default_help_text_data }
        existing_service_provider.reload
        expect(existing_service_provider.logo_file).to be_attached
        expect(existing_service_provider.logo_file.checksum).to eq(good_upload_checksum)
      end
    end

    context 'and Production gate is enabled' do
      let (:existing_service_provider) do
        create( :service_provider,
                :ready_to_activate_ial_1,
                team: create(:team),
                issuer: "issuer:string:#{rand(1...1000)}",
                friendly_name: 'Friendly App')
      end

      before do
        allow(IdentityConfig.store).to receive_messages(prod_like_env: true)
        put :create, params: { service_provider: existing_service_provider }
      end

      it 'allows Login.gov Admins to update IAL on existing configs' do
        initial_ial = existing_service_provider.reload.attributes['ial']
        default_help_text_data = build(:wizard_step, step_name: 'help_text').wizard_form_data
        put :update, params: { id: 'authentication', wizard_step: { ial: 2 } }
        put :update, params: { id: 'help_text', wizard_step: default_help_text_data }
        updated_ial = existing_service_provider.reload.attributes['ial']
        expect(updated_ial).to_not eq(initial_ial)
      end
    end
  end

  context 'when a partner admin' do
    let(:wizard_steps_ready_to_go) do
      # The team needs to be persisted and with an ID or WizardStep validation will fail
      WizardStep.steps_from_service_provider(
        build(:service_provider, :ready_to_activate, team:),
        partner_admin,
      )
    end

    before do
      sign_in partner_admin
    end

    it 'can start the first step' do
      flag_in
      get :new
      expect(response).to be_redirect
      expect(response.redirect_url).to eq(service_config_wizard_url(Wicked::FIRST_STEP))
    end

    it 'is redirected if the flag is not set' do
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
              wizard_step: { cert: file },
            }
        logo_and_cert_step = WizardStep.where(step_name: 'logo_and_cert').last
        has_serial = logo_and_cert_step.certificates.any? { |c| c.serial.to_s == '10' }
        expect(has_serial).to eq(true)
      end
    end

    describe 'help_text' do
      # Slicing the PRESETS to skip the first entry (index 0)
      # because the first entry is the 'blank' entry that has no translation
      # and is easier to test separately
      let(:non_blank_sign_in_preset) { HelpText::PRESETS['sign_in'][1..-1].sample }
      let(:non_blank_sign_up_preset) { HelpText::PRESETS['sign_up'][1..-1].sample }
      let(:non_blank_forgot_password_preset) { HelpText::PRESETS['forgot_password'][1..-1].sample }

      it 'can create a new app' do
        wizard_steps_ready_to_go.each(&:save!)
        expect do
          put :update, params: {
            id: 'help_text',
            wizard_step: { help_text: {
              'sign_in' => { 'en' => 'blank' },
              'sign_up' => { 'en' => 'blank' },
              'forgot_password' => { 'en' => 'blank' },
            } },
          }
          error_messages = assigns['model'].errors.messages.merge(
            assigns['service_provider'].errors.messages,
          )
          expect(response).to be_redirect, "Not redirected. Errors found: #{error_messages}"
        end.to(change { ServiceProvider.count }.by(1))
        expect(response.redirect_url).to eq(service_provider_url(ServiceProvider.last))
        expect(assigns['service_provider']).to eq(ServiceProvider.last)
        expect(WizardStep.where(user: partner_admin)).to be_empty
      end

      it 'allows picking help text presets' do
        wizard_steps_ready_to_go.each(&:save!)
        settings_step = wizard_steps_ready_to_go.first.get_step('settings')

        expect do
          put :update, params: { id: 'help_text', wizard_step: { help_text: {
            'sign_in' => { 'en' => non_blank_sign_in_preset },
            'sign_up' => { 'en' => non_blank_sign_up_preset },
            'forgot_password' => { 'en' => non_blank_forgot_password_preset },
          } } }
        end.to(change { ServiceProvider.count }.by(1))
        actual_help_text = ServiceProvider.last.help_text
        expect(actual_help_text['sign_in']['en']).to eq(I18n.t(
          "service_provider_form.help_text.sign_in.#{non_blank_sign_in_preset}",
          agency: Team.find(settings_step.group_id).agency.name,
          sp_name: settings_step.friendly_name,
          locale: :en,
        ))
        expect(actual_help_text['sign_up']['en']).to eq(I18n.t(
          "service_provider_form.help_text.sign_up.#{non_blank_sign_up_preset}",
          agency: Team.find(settings_step.group_id).agency.name,
          sp_name: settings_step.friendly_name,
          locale: :en,
        ))
        expect(actual_help_text['forgot_password']['en']).to eq(I18n.t(
          "service_provider_form.help_text.forgot_password.#{non_blank_forgot_password_preset}",
          agency: Team.find(settings_step.group_id).agency.name,
          sp_name: settings_step.friendly_name,
          locale: :en,
        ))
      end

      it 'can set a preset help_text to blank' do
        wizard_steps_ready_to_go.each(&:save!)
        initial_help_text = {
          'sign_in' => { 'en' => non_blank_sign_in_preset },
          'sign_up' => { 'en' => non_blank_sign_up_preset },
          'forgot_password' => { 'en' => non_blank_forgot_password_preset },
        }
        put :update, params: { id: 'help_text', wizard_step: { help_text: initial_help_text } }
        new_service_provider = create(:service_provider, with_team_from_user: partner_admin)
        put :create, params: { service_provider: new_service_provider }
        context_to_be_blank = %w[sign_in sign_up forgot_password].sample
        updated_help_text = initial_help_text.merge(context_to_be_blank => { 'en' => 'blank' })
        put :update, params: { id: 'help_text', wizard_step: { help_text: updated_help_text } }
        new_service_provider.reload
        %w[sign_in sign_up forgot_password].each do |context|
          saved_help_text_for_context = new_service_provider.help_text[context]['en']
          if context == context_to_be_blank
            expect(saved_help_text_for_context).to eq('')
          else
            expect(saved_help_text_for_context).to_not be_blank
          end
        end
      end
    end

    context 'and Production gate is enabled' do
      let (:existing_service_provider) do
        create( :service_provider,
                :ready_to_activate_ial_1,
                team: team,
                issuer: "issuer:string:#{rand(1...1000)}",
                friendly_name: 'Friendly App')
      end

      before do
        allow(IdentityConfig.store).to receive_messages(prod_like_env: true)
        put :create, params: { service_provider: existing_service_provider }
      end

      it 'does not allow Partners to update IAL on existing configs' do
        initial_ial = existing_service_provider.reload.attributes['ial']
        default_help_text_data = build(:wizard_step, step_name: 'help_text').wizard_form_data
        put :update, params: { id: 'authentication', wizard_step: { ial: '2' } }
        put :update, params: { id: 'help_text', wizard_step: default_help_text_data }
        # fails silently
        updated_ial = existing_service_provider.reload.attributes['ial']
        expect(updated_ial).to eq(initial_ial)
      end
    end
  end

  context 'when a user without team write privieleges' do
    let(:user) { create(:user_team, :partner_readonly, team:).user }
    let(:service_provider) { create(:service_provider, team:) }

    before do
      sign_in user
    end

    it 'cannot create from existing' do
      service_provider = create(:service_provider, team:)
      put :create, params: { service_provider: service_provider.id }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'cannot save' do
      WizardStep.steps_from_service_provider(service_provider, user).each(&:save!)
      default_help_text_data = build(:wizard_step, step_name: 'help_text').wizard_form_data
      put :update, params: { id: 'help_text', wizard_step: default_help_text_data }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'can save on a team with more permissions' do
      create(:user_team, :partner_admin, user: user, team: create(:team))
      WizardStep.steps_from_service_provider(service_provider, user).each(&:save!)
      default_help_text_data = build(:wizard_step, step_name: 'help_text').wizard_form_data
      put :update, params: { id: 'help_text', wizard_step: default_help_text_data }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when not logged in' do
    it 'requires authentication without checking flag status' do
      expect(IdentityConfig.store).not_to receive(:service_config_wizard_enabled)
      get :new
      expect(response).to be_redirect
      expect(response.redirect_url).to eq(root_url)
    end
  end
end
