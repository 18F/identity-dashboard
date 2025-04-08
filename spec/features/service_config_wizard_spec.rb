require 'rails_helper'

feature 'Service Config Wizard' do
  let(:team) { create(:team) }
  let(:logingov_admin) { create(:user, :logingov_admin, :with_teams) }

  # Currently must be Partner Admin or Partner Developer to create a service provider
  let(:user_membership) { create(:user_team, [:partner_admin, :partner_developer].sample, team:) }
  let(:user) { user_membership.user }

  let(:custom_help_text) do
    {
      'sign_in' => {
        'en' => 'Do sign in',
        'es' => 'Do sign in',
        'fr' => 'Do sign in',
        'zh' => 'Do sign in',
      },
      'sign_up' => { 'en' => 'Join Us', 'es' => 'Join Us', 'fr' => 'Join Us', 'zh' => 'Join Us' },
      'forgot_password' => {
        'en' => 'Get help',
        'es' => 'Get help',
        'fr' => 'Get help',
        'zh' => 'Get help',
      },
    }
  end
  let(:standard_help_text) do
    {
      'sign_in' => { 'en' => 'blank', 'es' => 'blank', 'fr' => 'blank', 'zh' => 'blank' },
      'sign_up' => {
        'en' => 'first_time',
        'es' => 'first_time',
        'fr' => 'first_time',
        'zh' => 'first_time',
      },
      'forgot_password' => { 'en' => 'blank', 'es' => 'blank', 'fr' => 'blank', 'zh' => 'blank' },
    }
  end

  context 'when admin' do
    before do
      login_as(logingov_admin)
    end

    it 'can remember something filled in' do
      app_name = "name#{rand(1..1000)}"
      test_name = "Test name #{rand(1..1000)}"
      issuer_name = "test:config:#{rand(1...1000)}"
      help_text = {
        'sign_in' => { 'en' => 'hello', 'es' => 'hola', 'fr' => 'bonjour', 'zh' => '你好' },
        'sign_up' => { 'en' => 'hello', 'es' => 'hola', 'fr' => 'bonjour', 'zh' => '你好' },
        'forgot_password' => { 'en' => 'hello', 'es' => 'hola', 'fr' => 'bonjour', 'zh' => '你好' },
      }
      visit new_service_config_wizard_path
      click_on 'Next' # Skip the intro page
      current_step = find('.step-indicator__step--current')
      expect(current_step.text).to match(t('service_provider_form.wizard_steps.settings'))
      fill_in('App name', with: app_name)
      fill_in('Friendly name', with: test_name)
      team_to_pick = logingov_admin.teams.sample
      select(team_to_pick.name, from: 'Team')
      click_on 'Next'
      current_step = find('.step-indicator__step--current')
      expect(current_step.text).to match(t('service_provider_form.wizard_steps.protocol'))
      click_on 'Back'
      current_step = find('.step-indicator__step--current')
      expect(current_step.text).to match(t('service_provider_form.wizard_steps.settings'))
      expect(find('#wizard_step_friendly_name').value).to eq(test_name)
      click_on 'Next' # /protocol
      click_on 'Next' # /authentication
      click_on 'Next' # /issuer
      fill_in('Issuer', with: issuer_name)
      click_on 'Next' # /logo_and_cert
      click_on 'Next' # /redirects
      click_on 'Next' # /help_text
      HelpText::CONTEXTS.each do |context|
        HelpText::LOCALES.each do |locale|
          fill_in(
            "wizard_step_help_text_#{context}_#{locale}",
            with: help_text[context][locale],
          )
        end
      end
      click_on 'Create app' # details page
      click_on 'Edit'
      visit service_config_wizard_path('help_text')
      HelpText::CONTEXTS.each do |context|
        HelpText::LOCALES.each do |locale|
          expect(
            find("#wizard_step_help_text_#{context}_#{locale}").value,
          ).to eq(help_text[context][locale])
        end
      end
    end

    it 'displays and saves the correct default options while walking through the steps' do
      create(:user_team, :partner_admin, user:)
      team_to_pick = user.teams.sample
      # These are expected values, listed in the order the currently appear in the step forms
      # These are all required values that we'll fill in, or expected default values
      expected_data = {
        # settings
        'group_id' => team_to_pick.id, # required
        'prod_config' => 'false',
        'app_name' => 'my-app', # required
        'friendly_name' => 'My App', # required
        'description' => '',
        # auth
        'identity_protocol' => 'saml', # not default, but we're using SAML to test other defaults
        'ial' => '1',
        'default_aal' => '0',
        'attribute_bundle' => [],
        # issuer
        'issuer' => 'test:saml:issuer', # required
        # logo_and_cert
        # # TODO: add data, skipped for now
        # redirect uris
        'acs_url' => 'http://localhost/acs', # required for SAML
        'assertion_consumer_logout_service_url' => '',
        'sp_initiated_login_url' => '',
        'block_encryption' => 'aes256-cbc',
        'signed_response_message_requested' => 'true',
        'return_to_sp_url' => 'http://localhost/sp_return', # required for SAML
        'push_notification_url' => '',
        'redirect_uris' => [],
        # help text
        'help_text' => {
          'sign_in' => {
            'en' => 'hello',
            'es' => 'hola',
            'fr' => 'bonjour',
            'zh' => '你好',
          },
          'sign_up' => {
            'en' => 'hello',
            'es' => 'hola',
            'fr' => 'bonjour',
            'zh' => '你好',
          },
          'forgot_password' => {
            'en' => 'hello',
            'es' => 'hola',
            'fr' => 'bonjour',
            'zh' => '你好',
          },
        },
      }
      visit new_service_config_wizard_path
      click_on 'Next' # Skip the intro page
      team_field = find_field('Team')
      team_field_options = team_field.find_all('option')
      current_value = team_field.value
      team_options_with_current_value = team_field_options.select do |opt|
        opt.value == current_value
      end
      expect(team_field_options.count).to_not eq(1)
      expect(team_options_with_current_value.count).to eq(1)
      expect(team_options_with_current_value.first.text).to eq('- Select -')
      fill_in('App name', with: expected_data['app_name'])
      fill_in('Friendly name', with: expected_data['friendly_name'])
      select(team_to_pick.name, from: 'Team')
      expect(team_field.value).to eq(team_to_pick.id.to_s)
      click_on 'Next'
      choose 'SAML' # not default, but we're using SAML to test other defaults
      click_on 'Next'
      click_on 'Next' # skip auth step
      fill_in('Issuer', with: expected_data['issuer'])
      click_on 'Next'
      attach_file('Choose a cert file', 'spec/fixtures/files/testcert.pem')
      click_on 'Next' # Skip logo upload for now
      encryption_field = find_field('SAML Assertion Encryption')
      expected_text = ServiceProvider.block_encryptions.keys.join(' ')
      expect(encryption_field.text).to eq(expected_text)
      expected_key = ServiceProvider.block_encryptions.keys.last
      expect(encryption_field.value.downcase).to eq(expected_key.downcase)
      fill_in('Assertion Consumer Service URL', with: expected_data['acs_url'])
      fill_in('Return to App URL', with: expected_data['return_to_sp_url'])
      click_on 'Next'
      # Help text
      HelpText::CONTEXTS.each do |context|
        HelpText::LOCALES.each do |locale|
          fill_in(
            "wizard_step_help_text_#{context}_#{locale}",
            with: expected_data['help_text'][context][locale],
          )
        end
      end
      click_on 'Create app'

      saved_config_data = ServiceProvider.find_by(issuer: expected_data['issuer'])
      expect(current_url).to match(service_providers_url(saved_config_data.id)),
                             'failed to redirect to the service provider details page'
      expected_data.each_key do |key|
        next if key == 'default_aal'

        expect(saved_config_data[key].to_s)
          .to eq(expected_data[key].to_s),
              "#{key} expected: #{expected_data[key]}\n#{key} received: #{saved_config_data[key]}"
      end

      expect(saved_config_data['default_aal']).to be_nil

      expect(saved_config_data['certs']).
        to eq([fixture_file_upload('spec/fixtures/files/testcert.pem').read]),
           'cert failed to save as expected'
      expect(page).to have_content(t(
        'notices.service_provider_saved',
        issuer: expected_data['issuer'],
      ))
      expect(page).to_not have_content(t('notices.service_providers_refresh_failed'))
      expect(WizardStep.all_step_data_for_user(logingov_admin))
        .to eq({}), 'error: draft data not deleted'
    end

    it 'correctly labels team in error when team is blank' do
      # These are expected values, listed in the order the currently appear in the step forms
      # These are all required values that we'll fill in, or expected default values
      expected_data = {
        # settings
        'group_id' => '', # required
        'prod_config' => 'false',
        'app_name' => 'my-app', # required
        'friendly_name' => 'My App', # required
        'description' => '',
      }
      visit new_service_config_wizard_path
      click_on 'Next' # Skip the intro page
      fill_in('App name', with: expected_data['app_name'])
      fill_in('Friendly name', with: expected_data['friendly_name'])
      click_on 'Next'
      expect(page).to have_content('Team can\'t be blank')
    end

    it 'shows uploaded logo file errors' do
      visit service_config_wizard_path('logo_and_cert')
      attach_file('Choose a file', 'spec/fixtures/logo_with_script.svg')
      expect { click_on 'Next' }.to_not(change(WizardStep, :count))
      actual_error_message = find('#logo-upload-error').text
      expected_error_message = I18n.t(
        'service_provider_form.errors.logo_file.has_script_tag',
        filename: 'logo_with_script.svg',
      )
      expect(actual_error_message).to eq(expected_error_message)
    end

    it 'can edit an existing config' do
      existing_config = create(:service_provider, :ready_to_activate_ial_1)
      visit service_provider_path(existing_config)
      click_on 'Edit'
      expect(find_field('App name').value).to eq(existing_config.app_name)
      click_on 'Next'
      # Skip making changes to protocol options
      click_on 'Next'
      # Skip making changes to auth options
      click_on 'Next'
      issuer_field = find('#wizard_step_issuer')
      expect(issuer_field.value).to eq(existing_config.issuer)
      expect(issuer_field).to be_disabled

      # If we can't edit the issuer, 'Next' shouldn't be a form submission
      expect(has_no_button?('Next')).to be_truthy
      expect(has_link?('Next')).to be_truthy
      click_on 'Next'

      attach_file('Choose a cert file', 'spec/fixtures/files/testcert.pem')
      click_on 'Next'
      expected_push_url = "https://localhost/#{rand(1..1000)}"
      fill_in('Push notification URL', with: expected_push_url)
      click_on 'Next'
      # Skip making changes to help text
      click_on 'Update app'
      existing_config.reload
      expect(existing_config.push_notification_url).to eq(expected_push_url)
    end

    it 'saves standard Help text on edit' do
      existing_config = create(:service_provider,
                               :ready_to_activate,
                               help_text: standard_help_text)
      visit service_provider_path(existing_config)
      click_on 'Edit'
      visit service_config_wizard_path('help_text')
      click_on 'Update app'
      # rubocop:disable Layout/LineLength
      content = "help_text: sign_in: en: '' es: '' fr: '' zh: '' sign_up: en: First time here from #{existing_config.friendly_name}? Your old #{existing_config.friendly_name} username and password won’t work. Create a Login.gov account with the same email used previously. es: ¿Es la primera vez que visita #{existing_config.friendly_name}? Su antiguo nombre de usuario y contraseña de #{existing_config.friendly_name} ya no funcionan. Cree una cuenta en Login.gov con el mismo correo electrónico que usó anteriormente. fr: C’est la première fois que vous vous connectez à #{existing_config.friendly_name}? Vos anciens nom d’utilisateur et mot de passe pour accéder à #{existing_config.friendly_name} ne fonctionneront pas. Créez un compte Login.gov avec la même adresse e-mail que celle utilisée antérieurement. zh: 第一次从 #{existing_config.friendly_name} 来到这里？您的旧 #{existing_config.friendly_name} 用户名和密码将不起作用。用之前使用的同一电子邮件地址 来设立一个 Login.gov帐户。 forgot_password: en: '' es: '' fr: '' zh: ''"
      # rubocop:enable Layout/LineLength
      expect(page).to have_content(content)
    end

    describe 'and Production gate is enabled' do
      before do
        allow(IdentityConfig.store).to receive_messages(
          prod_like_env: true,
          edit_button_uses_service_config_wizard: true,
        )
      end

      it 'allows Login.gov Admin to set initial IAL' do
        visit service_config_wizard_path('settings')
        select(logingov_admin.teams[0].name, from: 'Team')
        fill_in('App name', with: "name#{rand(1..1000)}")
        fill_in('Friendly name', with: "Test name #{rand(1..1000)}")
        click_on 'Next'
        visit service_config_wizard_path('authentication')
        expect(page.find('#wizard_step_ial_1').disabled?).to be(false)
        expect(page.find('#wizard_step_ial_2').disabled?).to be(false)
      end

      it 'allows Login.gov Admin to update IAL' do
        existing_config = create(:service_provider,
                               :ready_to_activate_ial_1,
                               team: logingov_admin.teams[0])
        visit service_provider_path(existing_config)
        click_on 'Edit'
        visit service_config_wizard_path('authentication')
        expect(page.find('#wizard_step_ial_1').disabled?).to be(false)
        expect(page.find('#wizard_step_ial_2').disabled?).to be(false)
      end
    end
  end

  context 'when not login.gov admin' do
    before do
      login_as(user)
    end

    describe 'starting at the service provider index' do
      let(:first_step) { ServiceConfigWizardController::STEPS[0] }

      it 'goes to the first wizard step' do
        visit service_providers_path
        click_on 'Create a new app'
        expect(page).to have_current_path(service_config_wizard_path(first_step))
      end

      context 'when setup wizard is already started' do
        let(:new_name) { "Initial Name #{rand(1..1000)}" }
        let(:new_friendly_name) { "Initial Friendly Name #{rand(1..1000)}" }

        before do
          visit service_providers_path
          click_on 'Create a new app'
          click_on 'Next'
          fill_in('App name', with: new_name)
          fill_in('Friendly name', with: new_friendly_name)
          select(team.name, from: 'Team')
          click_on 'Next'
        end

        it 'wipes existing steps and starts fresh' do
          saved_steps = WizardStep.where("wizard_form_data->>'group_id' = CAST(? as varchar)",
                                          team.id).count
          expect(saved_steps).to be(1)

          visit service_providers_path
          click_on 'Create a new app'
          expect(page).to have_current_path(service_config_wizard_path(first_step))
          saved_steps = WizardStep.where("wizard_form_data->>'group_id' = CAST(? as varchar)",
                                          team.id).count
          expect(saved_steps).to be(0)
        end
      end
    end

    it 'is redirected to service_providers if not flagged in' do
      allow(IdentityConfig.store).to receive(:service_config_wizard_enabled).
        at_least(ServiceConfigWizardController::STEPS.count + 1).
        and_return(nil)
      visit new_service_config_wizard_path
      expect(current_url).to eq(service_providers_url)
      ServiceConfigWizardController::STEPS.each do |step_name|
        visit new_service_config_wizard_path(step_name)
        expect(current_url).to eq(service_providers_url)
      end
    end

    context 'when on Redirects page' do
      it 'renders Failure to proof URL input if IAL2 is selected' do
        existing_config = create(:service_provider,
                                 :ready_to_activate_ial_2,
                                 team:)
        visit service_provider_path(existing_config)
        click_on 'Edit'
        visit service_config_wizard_path('redirects')

        expect(page).to have_content(t('simple_form.labels.service_provider.failure_to_proof_url'))
      end

      it 'does not render Failure to proof URL input if IAL1 is selected' do
        existing_config = create(:service_provider,
                                 :ready_to_activate_ial_1,
                                 team:)
        visit service_provider_path(existing_config)
        click_on 'Edit'
        visit service_config_wizard_path('redirects')

        expect(page).to_not have_content(
          t('simple_form.labels.service_provider.failure_to_proof_url'),
        )
      end

      it 'validates Failure to proof URL input' do
        existing_config = create(:service_provider,
                                 :ready_to_activate_ial_2,
                                 team:)
        visit service_provider_path(existing_config)
        click_on 'Edit'
        visit service_config_wizard_path('redirects')

        fill_in(t('simple_form.labels.service_provider.failure_to_proof_url'), with: '')
        click_on 'Next'
        expect(page).to have_content(
          "#{t('simple_form.labels.service_provider.failure_to_proof_url').
          capitalize} can't be empty",
        )

        fill_in(t('simple_form.labels.service_provider.failure_to_proof_url'), with: 'hello')
        click_on 'Next'
        expect(page).to have_content(
          "#{t('simple_form.labels.service_provider.failure_to_proof_url').capitalize} is invalid",
        )

        fill_in(t('simple_form.labels.service_provider.failure_to_proof_url'), with: 'https://test.gov')
        click_on 'Next'
        expect(page).to_not have_content(
          t('simple_form.labels.service_provider.failure_to_proof_url').
          capitalize,
        )
      end
    end

    it 'renders Help text as expected' do
      allow(IdentityConfig.store).to receive_messages(service_config_wizard_enabled: true)
      visit service_config_wizard_path('help_text')

      find_all('.usa-radio__input[checked]').each do |input|
        expect(input.value).to eq('blank')
      end
      # rubocop:disable Layout/LineLength
      choose 'Sign in to Login.gov with your {Agency} email.'
      choose 'Create a Login.gov account using the same email provided on your application.'
      choose 'If you are having trouble accessing your Login.gov account, visit the Login.gov help center for support.'
      expect(page).to have_checked_field('wizard_step_help_text_sign_in_en_agency_email')
      expect(page).to have_checked_field('wizard_step_help_text_sign_up_en_same_email')
      expect(page).to have_checked_field('wizard_step_help_text_forgot_password_en_troubleshoot_html')
      # rubocop:enable  Layout/LineLength
    end

    it 'renders read-only with custom Help text' do
      existing_config = create(:service_provider,
                               :ready_to_activate,
                               help_text: custom_help_text,
                               team: team)
      visit service_provider_path(existing_config)
      click_on 'Edit'
      visit service_config_wizard_path('help_text')

      HelpText::CONTEXTS.each do |context|
        HelpText::LOCALES.each do |locale|
          expect(page).to have_content(custom_help_text[context][locale])
        end
      end
    end

    describe 'and Production gate is enabled' do
      before do
        allow(IdentityConfig.store).to receive_messages(
          prod_like_env: true,
          edit_button_uses_service_config_wizard: true,
        )
      end

      it 'allows Partners to set initial IAL' do
        visit service_config_wizard_path('settings')
        select(team.name, from: 'Team')
        fill_in('App name', with: "name#{rand(1..1000)}")
        fill_in('Friendly name', with: "Test name #{rand(1..1000)}")
        click_on 'Next'
        visit service_config_wizard_path('authentication')
        expect(page.find('#wizard_step_ial_1').disabled?).to be(false)
        expect(page.find('#wizard_step_ial_2').disabled?).to be(false)
      end

      it 'does not allow Partners to edit IAL' do
        existing_config = create(:service_provider,
                               :ready_to_activate_ial_1,
                               team:)
        visit service_provider_path(existing_config)
        click_on 'Edit'
        expect(page).to_not have_content('Unauthorized')
        visit service_config_wizard_path('authentication')
        expect(page.find('#wizard_step_ial_1').disabled?).to be(true)
        expect(page.find('#wizard_step_ial_2').disabled?).to be(true)
      end
    end
  end

  context 'when partner readonly' do
    let(:user_membership) { create(:user_team, :partner_readonly, team:) }
    let(:user) { user_membership.user }

    it 'displays an unauthorized page' do
      login_as user
      visit new_service_config_wizard_path
      expect(page).to have_content('Unauthorized')
      expect(page).to_not have_content('Next')
    end
  end

  context 'when selecting OIDC' do
    before do
      allow(IdentityConfig.store).to receive_messages(service_config_wizard_enabled: true)
      app_name = "name#{rand(1..1000)}"
      test_name = "Test name #{rand(1..1000)}"
      user_to_login = [logingov_admin, user].sample
      login_as(user_to_login)
      visit service_config_wizard_path('settings')
      select(user_to_login.teams.sample.name, from: 'Team')
      fill_in('App name', with: app_name)
      fill_in('Friendly name', with: test_name)
      click_on 'Next'
      visit service_config_wizard_path('protocol')
      choose ['OpenID Connect Private Key JWT', 'OpenID Connect PKCE'].sample
      click_on 'Next'
    end

    it 'shows OIDC help text' do
      visit service_config_wizard_path('authentication')
      first_para = find_all('p[class="usa-hint"]').first
      expect(first_para.text).to eq(
        'See "Type of Service Level" in the OpenID Connect Authorization section.',
      )
    end
  end

  context 'when selecting SAML' do
    before do
      allow(IdentityConfig.store).to receive_messages(service_config_wizard_enabled: true)
      app_name = "name#{rand(1..1000)}"
      test_name = "Test name #{rand(1..1000)}"
      user_to_login = [logingov_admin, user].sample
      login_as(user_to_login)
      visit service_config_wizard_path('settings')
      select(user_to_login.teams.sample.name, from: 'Team')
      fill_in('App name', with: app_name)
      fill_in('Friendly name', with: test_name)
      click_on 'Next'
      visit service_config_wizard_path('protocol')
      choose 'SAML'
      click_on 'Next'
    end

    it 'shows SAML help text' do
      visit service_config_wizard_path('authentication')
      first_para = find_all('p[class="usa-hint"]').first
      expect(first_para.text).to eq(
        'See "Type of Service Level" in the SAML Authentication section of the developer docs.',
      )
    end
  end
end
