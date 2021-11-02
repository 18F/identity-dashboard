require 'rails_helper'

feature 'Service Providers CRUD' do
  before do
    allow(IdentityConfig.store).to receive(:logo_upload_enabled).and_return(false)
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
      select 'IAL2', from: 'Identity Assurance Level (IAL)'
      select 'AAL2', from: 'Authentication Assurance Level (AAL)'

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
      expect(page).to have_content('IAL2')
      expect(page).to have_content('AAL2')
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

      expect(page).to have_content(t('simple_form.labels.service_provider.redirect_uris_oidc_label'))
    end
    # rubocop:enable Layout/LineLength
  end

  context 'admin user' do
    scenario 'can create service provider with user team' do
      admin = create(:admin)
      team = create(:team)
      login_as(admin)

      visit new_service_provider_path

      select team, from: 'service_provider[group_id]'
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

    scenario 'cannot send an empty attribute bundle to the backend' do
      admin = create(:admin)
      sp = create(:service_provider, :with_team)
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

      expect(page).to have_content('Contains invalid IAL attributes')
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
      select 'AAL3', from: 'Authentication Assurance Level (AAL)'
      choose 'SAML'
      click_on 'Update'

      expect(page).to have_content('Success')
      expect(page).to have_content(I18n.t('notices.service_providers_refreshed'))
      expect(page).to have_content('app description foobar')
      expect(page).to have_content('change service_provider name')
      expect(page).to have_content('email')
      expect(page).to have_content('AAL3')
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

      allow(ServiceProviderUpdater).to receive(:ping).and_return(false)

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

  describe 'IAA banner' do
    shared_examples 'a page with an IAA banner' do
      let(:user) { create(:user) }
      let(:sp) { create(:service_provider, user: user) }
      let(:prod_url) { 'https://developers.login.gov/production' }
      let(:partners_email) { 'partners@login.gov' }

      before { login_as(user) }

      it 'displays the banner' do
        visit path
        expect(page).to have_selector(:css, "a[href='#{prod_url}']")
        expect(page).to have_selector(:css, "a[href='mailto:#{partners_email}']")
      end
    end

    context 'new page' do
      let(:path) { new_service_provider_path }

      it_behaves_like 'a page with an IAA banner'
    end
    context 'show page' do
      let(:path) { service_provider_path(sp) }

      it_behaves_like 'a page with an IAA banner'
    end
    context 'edit page' do
      let(:path) { edit_service_provider_path(sp) }

      it_behaves_like 'a page with an IAA banner'
    end
  end
end
