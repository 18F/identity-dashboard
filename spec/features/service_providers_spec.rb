require 'rails_helper'

feature 'Service Providers CRUD' do
  before do
    allow(IdentityConfig.store).to receive(:logo_upload_enabled).and_return(false)
  end

  def strip_tags(str)
    ActionController::Base.helpers.strip_tags(str)
  end

  context 'Regular user' do
    scenario 'can create service provider' do
      user = create(:user, :with_teams)
      login_as(user)

      visit new_service_provider_path

      expect(page).to_not have_content('Approved')

      fill_in 'Friendly name', with: 'test service_provider'
      fill_in 'Issuer', with: 'urn:gov:gsa:openidconnect.profiles:sp:sso:GSA:app-prod'
      fill_in 'service_provider_logo', with: 'test.png'
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

    scenario 'saml fields are shown on sp show page when saml is selected' do
      user = create(:user, :with_teams)
      service_provider = create(:service_provider, :saml, user: user)
      login_as(user)

      visit service_provider_path(service_provider)

      expect(page).to have_content(strip_tags(t('service_provider_form.saml_redirects_html')))
      expect(page).to have_content(I18n.t('service_provider_form.saml_assertion_encryption'))
    end

    scenario 'oidc fields are shown on sp show page when oidc is selected' do
      user = create(:user, :with_teams)
      service_provider = create(:service_provider, :with_oidc_jwt, user: user)
      login_as(user)

      visit service_provider_path(service_provider)

      expect(page).to have_content(strip_tags(t('service_provider_form.oidc_redirects_html')))
    end

    scenario 'saml fields are shown on sp edit page when saml is selected' do
      user = create(:user, :with_teams)
      service_provider = create(:service_provider, :saml, user: user)
      login_as(user)

      visit edit_service_provider_path(service_provider)

      expect(page).to have_content(strip_tags(t('service_provider_form.saml_redirects_html')))
      expect(page).to have_content(I18n.t('service_provider_form.saml_assertion_encryption'))
      # rubocop:disable Layout/LineLength
      expect(page).to have_content(strip_tags(t('service_provider_form.assertion_consumer_service_url_html')))
      expect(page).to have_content(strip_tags(t('service_provider_form.assertion_consumer_logout_service_url_html')))
      # rubocop:enable Layout/LineLength
    end

    scenario 'oidc fields are shown on sp edit page when oidc is selected' do
      user = create(:user, :with_teams)
      service_provider = create(:service_provider, :with_oidc_jwt, user: user)
      login_as(user)

      visit edit_service_provider_path(service_provider)

      expect(page).to have_content(strip_tags(t('service_provider_form.oidc_redirects_html')))
    end

    scenario 'can update service provider team', :js do
      user = create(:user, :with_teams)
      service_provider = create(:service_provider, user: user)
      login_as(user)

      visit edit_service_provider_path(service_provider)
      fill_in 'service_provider_redirect_uris', with: 'https://foo.com'
      select user.teams[1].name, from: 'service_provider_group_id'
      click_on 'Update'

      service_provider.reload
      expect(service_provider.agency).to eq(user.teams[1].agency)
      expect(service_provider.agency).not_to eq(user.teams[0].agency)
    end

    scenario 'can update oidc service provider with multiple redirect uris', :js do
      user = create(:user, :with_teams)
      service_provider = create(:service_provider, :with_users_team, user: user)
      login_as(user)

      visit edit_service_provider_path(service_provider)
      fill_in 'service_provider_redirect_uris', with: 'https://foo.com'
      click_on 'Update'

      service_provider.reload
      expect(service_provider.redirect_uris).to eq(['https://foo.com'])

      visit edit_service_provider_path(service_provider)
      page.all('[name="service_provider[redirect_uris][]"]')[1].set 'https://bar.com'
      click_on 'Update'

      service_provider.reload
      expect(service_provider.redirect_uris).to eq(['https://foo.com', 'https://bar.com'])

      visit edit_service_provider_path(service_provider)
      page.all('[name="service_provider[redirect_uris][]"]')[0].set ''
      click_on 'Update'

      service_provider.reload
      expect(service_provider.redirect_uris).to eq(['https://bar.com'])
    end

    scenario 'can view all saml fields when editing a saml app', :js do
      user = create(:user, :with_teams)
      service_provider = create(:service_provider, :saml, :with_users_team, user: user)

      login_as(user)

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
      user = create(:user, :with_teams)
      service_provider = create(:service_provider, :saml, :with_users_team, user: user)

      login_as(user)

      visit edit_service_provider_path(service_provider)
      acs_input = find_field('service_provider_acs_url')
      submit_btn = find('input[name="commit"]')
      # unset required field
      acs_input.set('')

      submit_btn.click
      message = acs_input.native.attribute('validationMessage')
      expect(message).to eq 'Please fill out this field.'

      # fill field with invalid string
      acs_input.set('lorem ipsum')

      submit_btn.click
      expect(find('.service_provider_acs_url .usa-error-message').text).to eq('is invalid')

      # ensure that valid URL now submits properly
      acs_input.set('https://fake.gov/test/saml/sp_login')

      submit_btn.click
      expect(page).to have_no_selector('.usa-error-message')
    end

    scenario 'switching protocols when editing a saml sp should persist saml info', :js do
      user = create(:user, :with_teams)
      service_provider = create(:service_provider, :saml, :with_users_team, user: user)

      login_as(user)

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
      user = create(:user, :with_teams)
      service_provider = create(:service_provider, :saml, :with_users_team, user: user)
      login_as(user)

      visit edit_service_provider_path(service_provider)
      fill_in 'service_provider_redirect_uris', with: 'https://foo.com'
      click_on 'Update'

      service_provider.reload
      expect(service_provider.redirect_uris).to eq(['https://foo.com'])

      visit edit_service_provider_path(service_provider)
      page.all('[name="service_provider[redirect_uris][]"]')[1].set 'https://bar.com'
      click_on 'Update'

      service_provider.reload
      expect(service_provider.redirect_uris).to eq(['https://foo.com', 'https://bar.com'])

      visit edit_service_provider_path(service_provider)
      page.all('[name="service_provider[redirect_uris][]"]')[0].set ''
      click_on 'Update'

      service_provider.reload
      expect(service_provider.redirect_uris).to eq(['https://bar.com'])
    end

    scenario 'can view but not edit existing custom help text' do
      user = create(:user, :with_teams)
      service_provider = create(:service_provider, :with_users_team, user: user)

      login_as(user)

      visit edit_service_provider_path(service_provider)

      expect(page).to have_content('You can view your existing help text here')
      expect(page).to have_css('#service_provider_help_text_sign_in_en[readonly="readonly"]')
    end

    scenario 'uses radio buttons when help text is not custom' do
      user = create(:user, :with_teams)
      help_text_context = HelpText::CONTEXTS.sample
      initial_help_text = { help_text_context => {
        'en' => HelpText::PRESETS[help_text_context].sample,
      }}
      service_provider = create(:service_provider,
        :with_users_team,
        user: user,
        help_text: initial_help_text,
      )

      # The first option does not start out as an empty string
      expect(service_provider.help_text.fetch(HelpText::CONTEXTS.first, {})['en']).to_not eq('')

      login_as(user)

      visit edit_service_provider_path(service_provider)

      expect(page).to_not have_content('You can view your existing help text here')
      expect(page).to_not have_css('#service_provider_help_text_sign_in_en')
      expect(page).to have_content('You can choose from the default help text options')
      help_text_radio_options = find_all('fieldset.custom-help-text input[type=radio]')
      expect(help_text_radio_options.count).to be(HelpText::PRESETS.values.flatten.count)

      # The first option is currently labeled "Leave blank", so this checks out that logic
      help_text_radio_options.first.click
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
      user = create(:user, :with_teams)
      initial_help_text = { HelpText::CONTEXTS.sample => { HelpText::LOCALES.sample => 'Hi there!'}}
      service_provider = create(:service_provider,
        :with_users_team,
        user: user,
        help_text: initial_help_text,
      )

      login_as(user)

      visit edit_service_provider_path(service_provider)

      expect(page).to have_content('You can view your existing help text here')
      expect(page).to have_css('#service_provider_help_text_sign_in_en[readonly="readonly"]')
      expect(page).to_not have_content('You can choose from the default help text options')
      expect(page).to_not have_content('fieldset.custom-help-text input[type=radio]')
    end

    scenario 'cannot edit allow_prompt_login' do
      user = create(:user, :with_teams)
      service_provider = create(:service_provider, :saml, :with_users_team, user: user)
      login_as(user)

      visit edit_service_provider_path(service_provider)

      expect(page).not_to have_css('input#service_provider_allow_prompt_login')
    end

    scenario 'cannot edit email_nameid_format_allowed' do
      user = create(:user, :with_teams)
      service_provider = create(:service_provider, :saml, :with_users_team, user: user)
      login_as(user)

      visit edit_service_provider_path(service_provider)

      expect(page).not_to have_css('input#service_provider_email_nameid_format_allowed')
    end

    # rubocop:disable Layout/LineLength
    scenario 'can select default help text options for new configurations' do
      user = create(:user, :with_teams)
      login_as(user)

      friendly_name = '<Application Friendly Name>'
      agency = '<Agency>'

      #taken from service_providers.en.yml
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
      user = create(:user)
      login_as(user)

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
      user = create(:user)
      login_as(user)

      visit new_service_provider_path
      choose('service_provider_identity_protocol_openid_connect_private_key_jwt', allow_label_click: true)

      saml_attributes =
        %w[acs_url assertion_consumer_logout_service_url sp_initiated_login_url return_to_sp_url block_encryption signed_response_message_requested]
      saml_attributes.each do |atr|
        expect(page).to_not have_content(t("simple_form.labels.service_provider.#{atr}"))
      end

      expect(page).to have_content(strip_tags(t('service_provider_form.oidc_redirects_html')))
    end

    scenario 'IAL1 attributes shown when IAL1 is selected', :js do
      user = create(:user)
      login_as(user)

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
      user = create(:user)
      login_as(user)

      visit new_service_provider_path
      select(I18n.t('service_provider_form.ial_option_2'), from: 'Level of Service')

      attributes =
       %w[email all_emails verified_at x509_subject x509_presented first_name last_name dob ssn address1 address2 city state zipcode phone]

      attributes.each do |atr|
        selector = "[for=service_provider_attribute_bundle_#{atr}]"
        expect(page).to have_selector(selector, wait: 0.1)
      end
    end

    context 'help_text_options_feature_disabled' do
      before do
        allow(IdentityConfig.store).to receive(:help_text_options_feature_enabled).and_return(false)
      end

      scenario 'cannot add help text for new configurations' do
        user = create(:user, :with_teams)
        login_as(user)
        
        visit new_service_provider_path
  
        expect(page).to have_content('Do you need to add help text for your application? Contact us.')
        expect(page).not_to have_css('#service_provider_help_text_sign_in_en')
      end
    end

    # rubocop:enable Layout/LineLength
  end

  context 'admin user' do
    scenario 'can view SP with no team', versioning: true do
      admin = create(:admin)
      service_provider = create(:service_provider)
      login_as(admin)

      visit service_provider_path(service_provider)

      expect(page).to have_content(service_provider.friendly_name)
      version_info = find('#versions')
      expect(version_info).to have_content('Action: Create')
      expect(version_info).to have_content(service_provider.created_at.to_s)
    end

    scenario 'can edit help text' do
      help_text = '<p>Text with some basic <a href="www.hello.com">html tags</a></p>'
      admin = create(:admin)
      service_provider = create(:service_provider)
      login_as(admin)

      visit edit_service_provider_path(service_provider)

      expect(page).to have_content('You can specify help text')
      fill_in 'service_provider_help_text_sign_in_en', with: help_text
      click_on 'Update'

      service_provider.reload

      expect(page).to have_content(help_text)
    end

    scenario 'can see push_notification_url in YAML generator' do
      url = 'http://www.test.com'
      admin = create(:admin)
      sp = create(:service_provider, :with_team)
      login_as(admin)

      visit edit_service_provider_path(sp)
      fill_in 'Push notification URL', with: url
      click_on 'Update'

      expect(page).to have_content('Success')

      expect(page.find(:id, 'yaml')).to have_content("push_notification_url: #{url}")
    end

    scenario 'can create service provider with user team' do
      admin = create(:admin)
      team = create(:team)
      login_as(admin)

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

    scenario 'can publish service providers' do
      admin = create(:admin)
      login_as(admin)

      visit service_providers_all_path

      click_on t('forms.buttons.trigger_idp_refresh')
      expect(page).to have_content(I18n.t('notices.service_providers_refreshed'))
    end

    scenario 'can enable prompt=login for a service provider' do
      admin = create(:admin)
      sp = create(:service_provider, :with_team)
      login_as(admin)

      visit edit_service_provider_path(sp)
      check 'service_provider_allow_prompt_login'
      click_on 'Update'

      expect(page).to have_content('Success')
    end

    scenario 'can enable email NameID format for a service provider' do
      admin = create(:admin)
      sp = create(:service_provider, :with_team)
      login_as(admin)

      visit edit_service_provider_path(sp)
      check 'service_provider_email_nameid_format_allowed'
      click_on 'Update'

      expect(page).to have_content('Success')
    end

    scenario 'cannot send an empty attribute bundle to the backend with saml and ial2' do
      admin = create(:admin)
      sp = create(:service_provider, :with_team, :saml, :with_ial_2)
      login_as(admin)

      visit edit_service_provider_path(sp)
      uncheck 'email'
      click_on 'Update'

      expect(page).to have_content('Attribute bundle cannot be empty')
    end

    scenario 'cannot send IAL2 attributes for IAL1' do
      admin = create(:admin)
      sp = create(:service_provider, :with_team, ial: 1)
      login_as(admin)

      visit edit_service_provider_path(sp)
      check 'ssn'
      click_on 'Update'

      expect(page).to have_content('Contains ial 2 attributes when ial 1 is selected')
    end
  end

  context 'Update' do
    scenario 'user updates service provider' do
      user = create(:user, :with_teams)
      app = create(:service_provider, :with_users_team, user: user)
      login_as(user)

      visit edit_service_provider_path(app)

      fill_in 'Friendly name', with: 'change service_provider name'
      fill_in 'Description', with: 'app description foobar'
      select I18n.t('service_provider_form.aal_option_3'),
             from: 'Authentication Assurance Level (AAL)'
      choose 'SAML'
      click_on 'Update'

      expect(page).to have_content('Success')
      expect(page).to have_content(I18n.t('notices.service_providers_refreshed'))
      expect(page).to have_content('app description foobar')
      expect(page).to have_content('change service_provider name')
      expect(page).to have_content('email')
      expect(page).to have_content(I18n.t('service_provider_form.aal_option_3'))
    end
    scenario 'user updates service provider but service provider is invalid' do
      user = create(:user)
      app = create(:service_provider, user: user)
      login_as(user)

      allow_any_instance_of(ServiceProvider).to receive(:valid?).and_return(false)

      visit edit_service_provider_path(app)

      fill_in 'Friendly name', with: 'change service_provider name'
      fill_in 'Description', with: 'app description foobar'
      choose 'SAML'
      click_on 'Update'

      expect(page).not_to have_content('Success')
      expect(page).to have_content(I18n.t('notices.service_providers_refresh_failed'))
    end
    scenario 'user updates service provider but service provider updater fails' do
      user = create(:user, :with_teams)
      app = create(:service_provider, :with_users_team, user: user)
      login_as(user)

      visit edit_service_provider_path(app)

      allow(ServiceProviderUpdater).to receive(:post_update).and_return(false)

      fill_in 'Friendly name', with: 'change service_provider name'
      fill_in 'Description', with: 'app description foobar'
      choose 'SAML'
      check 'last_name'
      click_on 'Update'

      expect(page).to have_content(I18n.t('notices.service_providers_refresh_failed'))
    end

    context 'managing certificates' do
      let(:existing_serial) { '111222333444' }

      let(:user) { create(:user, :with_teams) }
      let(:sp) do
        create(:service_provider,
                     :with_users_team,

                     user: user,
                     certs: [build_pem(serial: existing_serial)])
      end

      before do
        login_as(user)
        visit edit_service_provider_path(sp)
      end

      scenario 'removing existing certificate' do
        within(page.find('.lg-card', text: existing_serial)) do
          check 'Remove this certificate'
        end
        click_on 'Update'

        expect(sp.reload.certificates).to be_empty
      end

      context 'file uploads', js: true do
        around do |ex|
          Tempfile.create(binmode: !file_content.ascii_only?) do |file|
            @file_path = file.path
            file.puts file_content
            file.close

            ex.run
          end
        end

        context 'uploading a valid PEM certificate' do
          let(:file_content) { build_pem }

          it 'shows the file name and does not have an error' do
            page.attach_file 'Choose a cert file', @file_path, make_visible: true

            expect(page).to have_content(File.basename(@file_path))

            error_field = page.find('.js-pem-input-error-message')
            expect(error_field.text).to be_empty
          end
        end

        context 'uploading a private key' do
          let(:file_content) { '----PRIVATE KEY----' }

          it 'shows an error indicating a private key' do
            page.attach_file 'Choose a cert file', @file_path, make_visible: true

            error_field = page.find('.js-pem-input-error-message')
            expect(error_field).to have_content('This is a private key')
          end
        end

        context 'uploading a DER-encoded file' do
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

  scenario 'Read' do
    user = create(:user)
    team = create(:team)
    app = create(:service_provider, team: team, user: user)
    login_as(user)

    visit service_provider_path(app)

    expect(page).to have_content(app.friendly_name)
    expect(page).to have_content(team)
    expect(page).to_not have_content('All service providers')
  end

  scenario 'Delete' do
    user = create(:user)
    app = create(:service_provider, user: user)
    login_as(user)

    visit service_provider_path(app)
    click_on 'Delete'

    expect(page).to have_content('Success')
  end

  describe 'Call to Action' do
    shared_examples 'a page with a CTA for production applications' do
      let(:user) { create(:user) }
      let(:sp) { create(:service_provider, user: user, prod_config: true) }
      let(:prod_url) { 'https://developers.login.gov/production' }
      let(:zendesk_ticket) { 'https://zendesk.login.gov/hc/en-us/requests/new?ticket_form_id=5663417357332' }

      before { login_as(user) }

      it 'displays the call to action' do
        visit path
        expect(page).to have_selector(:css, "a[href='#{prod_url}']")
        expect(page).to have_selector(:css, "a[href='#{zendesk_ticket}']")
      end
    end
  end
end
