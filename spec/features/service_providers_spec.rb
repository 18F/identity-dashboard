require 'rails_helper'

feature 'Service Providers CRUD' do
  let(:team) { create(:team) }
  let(:user_membership) do
    create(:user_team, role_name: [:partner_admin, :partner_developer].sample, team: team)
  end
  let(:user) { user_membership.user }
  let(:logingov_admin) { create(:user, :logingov_admin) }

  let(:user_to_log_in_as) { user }

  before do
    login_as user_to_log_in_as
  end

  def strip_tags(str)
    ActionController::Base.helpers.strip_tags(str)
  end
  # Tests with :js require JavaScript to ensure protocol fields are properly toggled
  context 'with a regular user' do
    scenario 'can create service provider' do
      visit new_service_provider_path

      expect(page).to_not have_content('Approved')

      fill_in 'Friendly name', with: 'test service_provider'
      fill_in 'Issuer', with: 'urn:gov:gsa:openidconnect.profiles:sp:sso:GSA:app-prod'
      attach_file('Choose a file', 'spec/fixtures/files/logo.svg')
      select user.teams[0].name, from: 'service_provider_group_id'
      select I18n.t('service_provider_form.ial_option_2'), from: 'Level of Service'
      select I18n.t('service_provider_form.aal_option_2'),
             from: 'Authentication Assurance Level (AAL)'

      check 'email'
      check 'first_name'
      check 'verified_at'

      Tempfile.create(['cert', '.crt']) do |tmp|
        File.write(tmp.path, build_pem)
        attach_file('cert', tmp.path)

        click_on 'Create'
      end

      expect(page).to have_content('Success')
      expect(page).to have_content(I18n.t('notices.service_providers_refreshed'))
      expect(page).to have_content('test service_provider')
      expect(page).to have_content('urn:gov:gsa:openidconnect.profiles:sp:sso:GSA:app-prod')
      expect(page).to have_content('email')
      expect(page).to have_content(user.teams[0].agency.name)
      expect(page).to have_content(I18n.t('service_provider_form.ial_option_2'))
      expect(page).to have_content(I18n.t('service_provider_form.aal_option_2'))
    end

    scenario 'cannot see or visit link to analytics path' do
      user_team = create(:user_team, :partner_developer, user: user_to_log_in_as)
      sp = create(:service_provider, team: user_team.team)
      visit service_providers_path
      expect(page).to_not have_content('Analytics')
      visit analytics_path(sp.id)
      expect(page).to have_content('Unauthorized')
    end

    scenario 'saml fields are shown on sp show page when saml is selected' do
      service_provider = create(:service_provider, :saml, team:)

      visit service_provider_path(service_provider)

      expect(page).to have_content(strip_tags(t('service_provider_form.redirect_uris_saml_html')))
      expect(page).to have_content(I18n.t('service_provider_form.saml_assertion_encryption'))
    end

    scenario 'oidc fields are shown on sp show page when oidc is selected' do
      service_provider = create(:service_provider, :with_oidc_jwt, team:)

      visit service_provider_path(service_provider)

      expect(page).to have_content(strip_tags(t('service_provider_form.redirect_uris_oidc_html')))
    end

    scenario 'saml fields are shown on sp edit page when saml is selected' do
      service_provider = create(:service_provider, :saml, team:)

      visit edit_service_provider_path(service_provider)

      expect(page).to have_content(strip_tags(t('service_provider_form.redirect_uris_saml_html')))
      expect(page).to have_content(I18n.t('service_provider_form.saml_assertion_encryption'))
      # rubocop:disable Layout/LineLength
      expect(page).to have_content(strip_tags(t('service_provider_form.assertion_consumer_service_url_html')))
      expect(page).to have_content(strip_tags(t('service_provider_form.assertion_consumer_logout_service_url_html')))
      # rubocop:enable Layout/LineLength
    end

    scenario 'oidc fields are shown on sp edit page when oidc is selected' do
      service_provider = create(:service_provider, :with_oidc_jwt, team:)

      visit edit_service_provider_path(service_provider)

      expect(page).to have_content(strip_tags(t('service_provider_form.redirect_uris_oidc_html')))
    end

    scenario 'can update service provider team' do
      other_team_membershp = create(:user_team, :partner_admin, user:)
      other_team = other_team_membershp.team
      service_provider = create(:service_provider, team:)

      visit edit_service_provider_path(service_provider)
      fill_in 'service_provider_redirect_uris', with: 'https://foo.com'
      select other_team.name, from: 'service_provider_group_id'
      click_on 'Update'

      service_provider.reload
      expect(service_provider.agency).to eq(other_team.agency)
      expect(service_provider.agency).to_not eq(team.agency)
    end

    scenario 'can update oidc service provider with multiple redirect uris', :js do
      service_provider = create(:service_provider, team:)

      visit edit_service_provider_path(service_provider)
      fill_in 'service_provider_redirect_uris', with: 'https://foo.com'
      click_on 'Update'
      expect(page).to have_content 'https://foo.com'

      service_provider.reload
      expect(service_provider.redirect_uris).to eq(['https://foo.com'])

      visit edit_service_provider_path(service_provider)
      page.all('[name="service_provider[redirect_uris][]"]')[1].set 'https://bar.com'
      click_on 'Update'
      expect(page).to have_content 'https://bar.com'

      service_provider.reload
      expect(service_provider.redirect_uris).to eq(['https://foo.com', 'https://bar.com'])

      visit edit_service_provider_path(service_provider)
      page.all('[name="service_provider[redirect_uris][]"]')[0].set ''
      click_on 'Update'
      expect(page).to_not have_content('https://foo.com')

      service_provider.reload
      expect(service_provider.redirect_uris).to eq(['https://bar.com'])
    end

    scenario 'can view all saml fields when editing a saml app', :js do
      service_provider = create(:service_provider, :saml, team:)

      visit edit_service_provider_path(service_provider)

      expect(find_field('Assertion Consumer Service URL', disabled: false).value).to eq(
        'https://fake.gov/test/saml/acs',
      )
      expect(find_field('Assertion Consumer Logout Service URL', disabled: false).value).to eq(
        'https://fake.gov/test/saml/logout',
      )

      expect(find_field('SP Initiated Login URL', disabled: false).value).to eq(
        'https://fake.gov/test/saml/sp_login',
      )
      expect(find_field('SAML Assertion Encryption', disabled: false).value).to eq(
        'aes256-cbc',
      )
    end

    scenario 'ACS URL is required with SAML protocol', :js do
      service_provider = create(:service_provider, :saml, team:)

      visit edit_service_provider_path(service_provider)
      acs_input = find_field('service_provider_acs_url')
      submit_btn = find('input[name="commit"]')
      # unset required field
      acs_input.set('')

      submit_btn.click
      acs_input = find_field('service_provider_acs_url')
      message = acs_input.native.attribute('validationMessage')
      expect(message).to eq 'Please fill out this field.'

      # fill field with invalid string
      acs_input.set('lorem ipsum')

      submit_btn.click
      acs_input = find_field('service_provider_acs_url')
      expect(find('.service_provider_acs_url .usa-error-message').text).to eq('Acs url is invalid')

      # ensure that valid URL now submits properly
      acs_input.set('https://fake.gov/test/saml/sp_login')

      submit_btn.click
      expect(page).to_not have_css('.usa-error-message')
    end

    scenario 'switching protocols when editing a saml sp should persist saml info', :js do
      service_provider = create(:service_provider, :saml, team:)

      visit edit_service_provider_path(service_provider)

      choose(
        'service_provider_identity_protocol_openid_connect_private_key_jwt',
        allow_label_click: true,
      )
      choose('service_provider_identity_protocol_saml', allow_label_click: true)

      expect(find_field('Assertion Consumer Service URL', disabled: false).value).to eq(
        'https://fake.gov/test/saml/acs',
      )
      expect(find_field('Assertion Consumer Logout Service URL', disabled: false).value).to eq(
        'https://fake.gov/test/saml/logout',
      )

      expect(find_field('SP Initiated Login URL', disabled: false).value).to eq(
        'https://fake.gov/test/saml/sp_login',
      )
      expect(find_field('SAML Assertion Encryption', disabled: false).value).to eq(
        'aes256-cbc',
      )
    end

    scenario 'can update saml service provider with multiple redirect uris', :js do
      service_provider = create(:service_provider, :saml, team:)

      visit edit_service_provider_path(service_provider)
      fill_in 'service_provider_redirect_uris', with: 'https://foo.com'
      click_on 'Update'
      expect(page).to have_content 'https://foo.com'

      service_provider.reload
      expect(service_provider.redirect_uris).to eq(['https://foo.com'])

      visit edit_service_provider_path(service_provider)
      page.all('[name="service_provider[redirect_uris][]"]')[1].set 'https://bar.com'
      click_on 'Update'

      expect(page).to have_content 'https://bar.com'
      service_provider.reload
      expect(service_provider.redirect_uris).to eq(['https://foo.com', 'https://bar.com'])

      visit edit_service_provider_path(service_provider)
      page.all('[name="service_provider[redirect_uris][]"]')[0].set ''
      click_on 'Update'

      expect(page).to_not have_content 'https://foo.com'

      service_provider.reload
      expect(service_provider.redirect_uris).to eq(['https://bar.com'])
    end

    scenario 'can view but not edit existing custom help text' do
      service_provider = create(:service_provider, team:)

      visit edit_service_provider_path(service_provider)

      expect(page).to have_content('You can view your existing help text here')
      expect(page).to have_css('#service_provider_help_text_sign_in_en[readonly="readonly"]')
    end

    scenario 'uses radio buttons when help text is not custom' do
      help_text_context = HelpText::CONTEXTS.sample
      initial_help_text = { help_text_context => {
        'en' => HelpText::PRESETS[help_text_context].sample,
      } }
      service_provider = create(:service_provider,
                                team: team,
                                help_text: initial_help_text)

      # The first option does not start out as an empty string
      expect(service_provider.help_text.fetch(HelpText::CONTEXTS.first, {})['en']).to_not eq('')

      visit edit_service_provider_path(service_provider)

      expect(page).to_not have_content('You can view your existing help text here')
      expect(page).to_not have_css('#service_provider_help_text_sign_in_en')
      expect(page).to have_content('You can choose from the default help text options')
      help_text_radio_options = find_all('fieldset.custom-help-text input[type=radio]')
      expect(help_text_radio_options.count).to be(HelpText::PRESETS.values.flatten.count)

      # The first option is "Leave blank" for `sign_in`, so this exercises the "Leave blank" logic
      help_text_radio_options.first.click
      # The last option is for `forgot_password` and is something other than "Leave blank"
      help_text_radio_options.last.click
      click_on 'Update'
      visit edit_service_provider_path(service_provider)

      # The database did update
      expect(service_provider.reload.help_text.to_json).to_not eq(initial_help_text.to_json)
      # The first option is now an empty string
      expect(service_provider.help_text.fetch(HelpText::CONTEXTS.first, {})['en']).to eq('')

      # We did not switch to the custom text inputs
      updated_radio_options = find_all('fieldset.custom-help-text input[type=radio]')
      expect(updated_radio_options.count).to be(HelpText::PRESETS.values.flatten.count)
      # The options stayed checked
      expect(updated_radio_options.first).
        to eq(find_all('fieldset.custom-help-text input[checked]').first)
      expect(updated_radio_options.last).
        to eq(find_all('fieldset.custom-help-text input[checked]').last)
    end

    scenario 'sees read-only text boxes when help text is custom' do
      initial_help_text = {
        HelpText::CONTEXTS.sample => { HelpText::LOCALES.sample => 'Hi there!' },
      }
      service_provider = create(:service_provider,
                                team: team,
                                help_text: initial_help_text)

      visit edit_service_provider_path(service_provider)

      expect(page).to have_content('You can view your existing help text here')
      expect(page).to have_css('#service_provider_help_text_sign_in_en[readonly="readonly"]')
      expect(page).to_not have_content('You can choose from the default help text options')
      expect(page).to_not have_content('fieldset.custom-help-text input[type=radio]')
    end

    scenario 'cannot edit allow_prompt_login' do
      service_provider = create(:service_provider, :saml, team:)

      visit edit_service_provider_path(service_provider)

      expect(page).to_not have_css('input#service_provider_allow_prompt_login')
    end

    scenario 'cannot edit email_nameid_format_allowed' do
      service_provider = create(:service_provider, :saml, team:)

      visit edit_service_provider_path(service_provider)

      expect(page).to_not have_css('input#service_provider_email_nameid_format_allowed')
    end

    # rubocop:disable Layout/LineLength
    scenario 'can select default help text options for new configurations' do
      friendly_name = '<Application Friendly Name>'
      agency = '<Agency>'

      # taken from service_providers.en.yml
      default_help_text_options = ['Leave blank',
      "First time here from #{friendly_name}? Your old #{friendly_name} username and password won’t work. Create a Login.gov account with the same email used previously.",
      "Sign in to Login.gov with your #{agency} email.",
      "Sign in to Login.gov with your #{agency} PIV/CAC.",
      "Create a Login.gov account using your #{agency} email.",
      'Create a Login.gov account using the same email provided on your application.',
      'If you are having trouble accessing your Login.gov account, visit the Login.gov help center for support.',
      ]

      visit new_service_provider_path

      expect(page).to have_content('You can choose from the default help text options')

      default_help_text_options.each do |text|
        expect(page).to have_content(text)
      end
    end

    scenario 'saml fields are shown when saml is selected', :js do
      visit new_service_provider_path
      choose('service_provider_identity_protocol_saml', allow_label_click: true)

      saml_attributes =
        %w[acs_url assertion_consumer_logout_service_url sp_initiated_login_url return_to_sp_url block_encryption signed_response_message_requested]
      saml_attributes.each do |atr|
        expect(page).to have_content(t("simple_form.labels.service_provider.#{atr}"))
      end

      # Redirect URIs (for oidc) is found in Additional Redirect URIs (saml) so instead we assert that
      # the oidc hint label is not found since the content there is dissimilar enough
      expect(page).to_not have_content(t('simple_form.labels.service_provider.redirect_uris_oidc_label'))
    end

    scenario 'oidc fields are shown when oidc is selected', :js do
      visit new_service_provider_path
      choose('service_provider_identity_protocol_openid_connect_private_key_jwt', allow_label_click: true)

      saml_attributes =
        %w[acs_url assertion_consumer_logout_service_url sp_initiated_login_url return_to_sp_url block_encryption signed_response_message_requested]
      saml_attributes.each do |atr|
        expect(page).to_not have_content(t("simple_form.labels.service_provider.#{atr}"))
      end

      expect(page).to have_content(strip_tags(t('service_provider_form.redirect_uris_oidc_html')))
    end

    scenario 'IAL1 attributes shown when IAL1 is selected', :js do
      visit new_service_provider_path
      select(I18n.t('service_provider_form.ial_option_1'), from: 'Level of Service')

      ial1_attributes = %w[email all_emails verified_at x509_subject x509_presented]
      ial2_attributes = %w[first_name last_name dob ssn address1 address2 city state zipcode phone]

      ial1_attributes.each do |atr|
        selector = "[for=service_provider_attribute_bundle_#{atr}]"
        expect(page).to have_selector(selector, wait: 0.1)
      end
      ial2_attributes.each do |atr|
        selector = "[for=service_provider_attribute_bundle_#{atr}]"
        expect(page).to_not have_selector(selector, wait: 0.1)
      end
    end

    scenario 'IAL2 attributes shown when IAL2 is selected', :js do
      visit new_service_provider_path
      select(I18n.t('service_provider_form.ial_option_2'), from: 'Level of Service')

      attributes =
        %w[email all_emails verified_at x509_subject x509_presented first_name last_name dob ssn address1 address2 city state zipcode phone]

      attributes.each do |atr|
        selector = "[for=service_provider_attribute_bundle_#{atr}]"
        expect(page).to have_selector(selector, wait: 0.1)
      end
    end

    context 'with help text options feature disabled' do
      before do
        allow(IdentityConfig.store).to receive(:help_text_options_feature_enabled).and_return(false)
      end

      scenario 'cannot add help text for new configurations' do
        visit new_service_provider_path

        expect(page).to have_content('Do you need to add help text for your application? Contact us.')
        expect(page).to_not have_css('#service_provider_help_text_sign_in_en')
      end
    end

    context 'can not view papertrail', :versioning do
      before do
        allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
      end

      scenario 'version history is not included on the page' do
        sp = create(:service_provider, :with_team, ial: 1)

        visit service_provider_path(sp)
        expect(page).to_not have_content('Version History')
      end
    end

    context 'and Production gate is enabled' do
      before do
        allow(IdentityConfig.store).to receive_messages(
          prod_like_env: true,
          edit_button_uses_service_config_wizard: false,
        )
      end

      it 'allows Partners to set initial IAL' do
        visit new_service_provider_path

        expect(page.find('#service_provider_ial').disabled?).to be(false)
      end

      it 'does not allow Partners to edit IAL' do
        existing_config = create(:service_provider,
                               :ready_to_activate_ial_1,
                               team:)
        visit service_provider_path(existing_config)
        click_on 'Edit'
        expect(page.find('#service_provider_ial').disabled?).to be(true)
      end
    end
    # rubocop:enable Layout/LineLength
  end

  context 'when login.gov admin' do
    let(:user_to_log_in_as) { logingov_admin }

    scenario 'can view SP with no team', :versioning do
      service_provider = create(:service_provider)

      visit service_provider_path(service_provider)

      expect(page).to have_content(service_provider.friendly_name)
      version_info = find('#versions')
      expect(version_info).to have_content('Action: Create')
      expect(version_info).to have_content(service_provider.created_at.to_s)
    end

    scenario 'editing some preset help text but not all' do
      not_blank_sign_up_preset = ['agency_email', 'first_time'].sample
      not_blank_sign_in_preset = ['agency_email', 'first_time'].sample
      help_text_en = '<p>Text with some basic <a href="www.hello.com">html</a></p>'
      help_text_es = '<p>Palabras con <a href="www.hello.com">html</a> simple</p>'

      # Let's create a service provider with some defaults and some not
      service_provider = build(:service_provider, :with_team)
      service_provider.help_text = {
        sign_up: { en: not_blank_sign_up_preset },
        sign_in: { en: not_blank_sign_in_preset, fr: not_blank_sign_in_preset },
        forgot_password: { en: HelpText::PRESETS['forgot_password'].sample },
      }
      service_provider.save!

      allow(IdentityConfig.store).to receive(:service_config_wizard_enabled).and_return(false)

      visit edit_service_provider_path(service_provider)

      expect(page).to have_content('You can specify help text')
      fill_in 'service_provider_help_text_sign_in_en', with: help_text_en
      fill_in 'service_provider_help_text_forgot_password_es', with: help_text_es
      click_on 'Update'
      expect(current_url).to eq(service_provider_url(service_provider))
      click_on 'Edit'

      expected_fr_signin_text = I18n.t(
        "service_provider_form.help_text.sign_in.#{not_blank_sign_in_preset}",
        locale: 'fr',
        sp_name: service_provider.friendly_name,
        agency: service_provider.agency&.name,
      )
      expect(find('#service_provider_help_text_sign_in_en').value).to eq(help_text_en)
      expect(find('#service_provider_help_text_sign_in_fr').value).to eq(expected_fr_signin_text)
      expect(find('#service_provider_help_text_forgot_password_es').value).to eq(help_text_es)
    end

    scenario 'can see push_notification_url in YAML generator' do
      url = 'http://www.test.com'
      sp = create(:service_provider, :with_team)

      visit edit_service_provider_path(sp)
      fill_in 'Push notification URL', with: url
      click_on 'Update'

      expect(page).to have_content('Success')

      expect(page.find(:id, 'yaml')).to have_content("push_notification_url: #{url}")
    end

    scenario 'can create service provider with user team' do
      team = create(:team)

      visit new_service_provider_path

      select team.name, from: 'service_provider[group_id]'
      fill_in 'Friendly name', with: 'test service_provider'
      fill_in 'Issuer', with: 'urn:gov:gsa:openidconnect.profiles:sp:sso:ABC:my-cool-app',
                        match: :prefer_exact
      check 'email'
      check 'verified_at'
      click_on 'Create'

      expect(page).to have_content('Success')
    end

    scenario 'can see and visit link to analytics path' do
      user_team = create(:user_team, :logingov_admin, user: user_to_log_in_as)
      sp = create(:service_provider, team: user_team.team)
      visit service_providers_path
      data_link = sp.friendly_name + ' data'
      expect(page).to have_content(data_link)
      click_on data_link
      expect(page).to have_content("#{sp.friendly_name.capitalize} Analytics Dashboard")
      expect(page).to have_content(sp.issuer)
    end

    scenario 'can enable prompt=login for a service provider' do
      user_to_log_in_as = logingov_admin
      sp = create(:service_provider, :with_team)

      visit edit_service_provider_path(sp)
      check 'service_provider_allow_prompt_login'
      click_on 'Update'

      expect(page).to have_content('Success')
    end

    scenario 'can enable email NameID format for a service provider' do
      sp = create(:service_provider, :with_team)

      visit edit_service_provider_path(sp)
      check 'service_provider_email_nameid_format_allowed'
      click_on 'Update'

      expect(page).to have_content('Success')
    end

    scenario 'cannot send an empty attribute bundle to the backend with saml and ial2' do
      sp = create(:service_provider, :with_team, :saml, :with_ial_2)

      visit edit_service_provider_path(sp)
      uncheck 'email'
      click_on 'Update'

      expect(page).to have_content('Attribute bundle cannot be empty')
    end

    scenario 'cannot send IAL2 attributes for IAL1' do
      sp = create(:service_provider, :with_team, ial: 1)

      visit edit_service_provider_path(sp)
      check 'ssn'
      click_on 'Update'

      expect(page).to have_content('Contains ial 2 attributes when ial 1 is selected')
    end

    context 'can view papertrail', :versioning do
      before do
        allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
      end

      scenario 'version history is included on the page' do
        sp = create(:service_provider, :with_team, ial: 1)

        visit service_provider_path(sp)
        expect(page).to have_content('Version History')
      end
    end

    context 'and Production gate is enabled' do
      before do
        allow(IdentityConfig.store).to receive_messages(
          prod_like_env: true,
          edit_button_uses_service_config_wizard: false,
        )
      end

      it 'allows Login.gov Admins to set initial IAL' do
        visit new_service_provider_path

        expect(page.find('#service_provider_ial').disabled?).to be(false)
      end

      it 'allows Login.gov Admins to edit IAL' do
        existing_config = create(:service_provider,
                               :ready_to_activate_ial_1,
                               team:)
        visit service_provider_path(existing_config)
        click_on 'Edit'
        expect(page.find('#service_provider_ial').disabled?).to be(false)
      end
    end
  end

  describe 'Update' do
    let(:user_to_log_in_as) { user }

    scenario 'user updates service provider' do
      app = create(:service_provider, with_team_from_user: user)

      visit edit_service_provider_path(app)

      fill_in 'Friendly name', with: 'change service_provider name'
      fill_in 'Description', with: 'app description foobar'
      select I18n.t('service_provider_form.aal_option_3'),
             from: 'Authentication Assurance Level (AAL)'
      choose 'SAML'
      fill_in 'Assertion Consumer Service URL', with: 'https://app.agency.gov/auth/saml/sso'
      fill_in 'Return to App URL', with: 'https://app.agency.gov'
      click_on 'Update'

      expect(page).to have_content('Success')
      expect(page).to have_content(I18n.t('notices.service_providers_refreshed'))
      expect(page).to have_content('app description foobar')
      expect(page).to have_content('change service_provider name')
      expect(page).to have_content('email')
      expect(page).to have_content(I18n.t('service_provider_form.aal_option_3'))
    end

    scenario 'user updates service provider but service provider is invalid' do
      app = create(:service_provider, team:)

      allow_any_instance_of(ServiceProvider).to receive(:valid?).and_return(false)

      visit edit_service_provider_path(app)

      fill_in 'Friendly name', with: 'change service_provider name'
      fill_in 'Description', with: 'app description foobar'
      choose 'SAML'
      click_on 'Update'

      expect(page).to_not have_content('Success')
      expect(page).to have_content(I18n.t('notices.service_providers_refresh_failed'))
    end

    scenario 'user updates service provider but service provider updater fails' do
      app = create(:service_provider, with_team_from_user: user)

      visit edit_service_provider_path(app)

      allow(ServiceProviderUpdater).to receive(:post_update).and_return(false)

      fill_in 'Friendly name', with: 'change service_provider name'
      fill_in 'Description', with: 'app description foobar'
      choose 'SAML'
      check 'last_name'
      click_on 'Update'

      expect(page).to have_content(I18n.t('notices.service_providers_refresh_failed'))
    end

    context 'when managing certificates' do
      let(:existing_serial) { '111222333444' }

      let(:sp) do
        create(:service_provider,
               team: team,
               certs: [build_pem(serial: existing_serial)])
      end

      before do
        visit edit_service_provider_path(sp)
      end

      scenario 'removing existing certificate' do
        within(page.find('.lg-card', text: existing_serial)) do
          check 'Remove this certificate'
        end
        click_on 'Update'

        expect(sp.reload.certificates).to be_empty
      end

      describe 'file uploads', :js do
        around do |ex|
          Tempfile.create(binmode: !file_content.ascii_only?) do |file|
            @file_path = file.path
            file.puts file_content
            file.close

            ex.run
          end
        end

        context 'with a valid PEM certificate' do
          let(:file_content) { build_pem }

          it 'shows the file name and does not have an error' do
            page.attach_file 'Choose a cert file', @file_path, make_visible: true

            expect(page).to have_content(File.basename(@file_path))

            error_field = page.find('.js-pem-input-error-message')
            expect(error_field.text).to be_empty
          end
        end

        context 'with a private key' do
          let(:file_content) { '----PRIVATE KEY----' }

          it 'shows an error indicating a private key' do
            page.attach_file 'Choose a cert file', @file_path, make_visible: true

            error_field = page.find('.js-pem-input-error-message')
            expect(error_field).to have_content('This is a private key')
          end
        end

        context 'with a DER-encoded file' do
          let(:file_content) { OpenSSL::X509::Certificate.new(build_pem).to_der }

          it 'show an error' do
            page.attach_file 'Choose a cert file', @file_path, make_visible: true

            error_field = page.find('.js-pem-input-error-message')
            expect(error_field).to have_content('does not appear to be PEM encoded')
          end
        end
      end
    end
  end

  describe 'starting on the `show` page' do
    let(:user_to_log_in_as) { user }

    let(:sp) { create(:service_provider, team:) }

    before do
      visit service_provider_path(sp)
    end

    scenario 'Read' do
      expect(page).to have_content(sp.friendly_name)
      expect(page).to have_content(team)
      expect(page).to_not have_content('All service providers')
    end

    describe 'the `edit_button_uses_service_config_wizard` flag' do
      it 'uses the 1-page form when flagged out' do
        allow(IdentityConfig.store).to receive_messages(
          service_config_wizard_enabled: true, edit_button_uses_service_config_wizard: false,
        )
        visit service_provider_path(sp)
        click_on 'Edit'
        expect(page).to have_current_path(edit_service_provider_path(sp))
      end

      it 'uses the wizard when flagged in' do
        allow(IdentityConfig.store).to receive_messages(
          service_config_wizard_enabled: true, edit_button_uses_service_config_wizard: true,
        )
        visit service_provider_path(sp)
        click_on 'Edit'
        expect(page).to have_current_path(service_config_wizard_path(:settings))
        friendly_name = find_by_id('wizard_step_friendly_name').value
        expect(friendly_name).to eq(sp.friendly_name)
      end
    end

    describe 'with a production config' do
      let(:sp) { create(:service_provider, team: team, prod_config: true) }

      it 'displays the production call to action links' do
        prod_url = 'https://developers.login.gov/production'
        zendesk_ticket = 'https://zendesk.login.gov/hc/en-us/requests/new?ticket_form_id=5663417357332'

        expect(page).to have_css("a[href='#{prod_url}']")
        expect(page).to have_css("a[href='#{zendesk_ticket}']")
      end
    end
  end

  scenario 'Delete' do
    app = create(:service_provider, team:)

    visit service_provider_path(app)
    click_on 'Delete'

    expect(page).to have_content('Success')
  end
end
