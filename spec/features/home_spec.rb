require 'rails_helper'

feature 'Home' do
  context 'when viewing the home page' do
    scenario 'you should see intro and appropriate links' do
      visit root_path

      expect(page).to have_content(I18n.t('home.landing_title'))
      expect(page).to have_content(I18n.t('home.dev_docs'))
      expect(page).to have_content('Become a Partner')
      expect(page).to have_content(I18n.t('links.sign_in'))
    end

    scenario 'you should be able to nav to system use page' do
      visit root_path
      click_on(I18n.t('links.sign_in'))

      expect(page).to have_content(I18n.t('home.system_use'))
      expect(page).to have_content(I18n.t('home.system_agree'))
      expect(page).to have_css('[action="/auth/logindotgov"]')
    end

    scenario 'page should have sandbox logo in non-prod-like environments' do
      visit root_path

      expect(page.find('.usa-logo__img')['src']).to have_content(/LG-PP-Sandbox-[a-z 0-9]*.svg/)
    end

    scenario 'page should have production logo in prod-like environments' do
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
      visit root_path

      expect(page.find('.usa-logo__img')['src']).to have_content(/LG-PP-Production-[a-z 0-9]*.svg/)
    end
  end

  context 'when login.gov admin' do
    let(:logingov_admin) { create(:user, :logingov_admin) }

    before do
      login_as(logingov_admin)
      visit root_path
    end

    scenario 'should see manage teams and manage users' do
      expect(page).to have_content('Teams')
      expect(page).to have_content('Users')
    end

    context 'should see admin nav menu items' do
      scenario 'on all envs' do
        expect(page).to have_button('Admin')
        click_on 'Admin'
        all_configs = find_link 'All configurations'
        expect(all_configs['href']).to eq(service_providers_all_path)
        all_users = find_link 'Users'
        expect(all_users['href']).to eq(users_path)
        all_teams = find_link 'All teams'
        expect(all_teams['href']).to eq(teams_all_path)
        security_events = find_link 'All security events'
        expect(security_events['href']).to eq(security_events_all_path)
        banners = find_link 'Banner messages'
        expect(banners['href']).to eq(banners_path)
        api_auth_link = find_link 'Your API auth token'
        expect(api_auth_link['href']).to eq(auth_tokens_path)
        deleted_configs = find_link 'Deleted configurations'
        expect(deleted_configs['href']).to eq(service_providers_deleted_path)
      end

      scenario 'on sandbox' do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(false)
        visit root_path
        click_on 'Admin'
        user_csv_link = find_link 'User permissions report'
        expect(user_csv_link['href']).to eq(internal_reports_user_permissions_path(format: 'csv'))
        extracts = find_link 'Configuration extraction'
        expect(extracts['href']).to eq(extracts_path)
      end

      scenario 'on production' do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
        visit root_path
        click_on 'Admin'
        airtable_link = find_link 'Connect with Airtable'
        expect(airtable_link['href']).to eq(airtable_path)
      end
    end
  end

  context 'a user who is not an admin' do
    let(:user) { create(:user) }

    before do
      login_as(user)
      visit root_path
    end

    # this also tests application_helper.rb#page_heading
    scenario 'should see an appropriate page title' do
      expect(page.title).to eq('Welcome | Login.gov Partner Portal Sandbox')
    end

    scenario 'should see manage teams and not see manage users' do
      expect(page).to_not have_button('Admin')
      expect(page).to have_content(I18n.t('headings.welcome'))
    end

    scenario 'can click on checklist accordion', :js do
      expect(page).to have_css('.usa-accordion > button[aria-expanded="false"]')
      expect(page).to_not have_content('Data you need')
      click_on 'checklist'
      expect(page).to have_css('.usa-accordion > button[aria-expanded="true"]')
      expect(page).to_not have_css('.usa-accordion > button[aria-expanded="false"]')
      expect(page).to have_content('Data you need')
    end

    scenario 'is logged out after Devise timeout' do
      expect(user.timedout?(IdentityConfig.store.devise_timeout_minutes.minutes.ago)).to be_truthy
    end
  end
end
