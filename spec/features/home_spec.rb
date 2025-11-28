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

    scenario 'should see admin nav menu items' do
      expect(page).to have_button('Admin')
      click_on 'Admin'
      api_auth_link = find_link 'Your API auth token'
      expect(api_auth_link['href']).to eq(auth_tokens_path)
      user_csv_link = find_link 'User permissions report'
      expect(user_csv_link['href']).to eq(internal_reports_user_permissions_path(format: 'csv'))
    end
  end

  context 'a user who is not an admin' do
    let(:user) { create(:user) }

    before do
      login_as(user)
      visit root_path
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
  end

  feature 'session timeout' do
    let(:user) { create(:user) }

    before do
      freeze_time
      travel_to last_access_time do
        login_as(user)
        visit root_path
      end
    end

    after do
      unfreeze_time
    end

    describe 'when last access time is older than the timeout threshold' do
      let(:last_access_time) { (IdentityConfig.store.devise_timeout_minutes + 1).minutes.ago }

      it 'is logged out after Devise timeout' do
        visit root_path
        expect(page).to have_content('Your session expired. Please sign in again to continue.')
      end

      it 'logs the session duration' do
        flunk
      end
    end

    describe 'when last access time is newer than the timeout threshold' do
      let(:last_access_time) { (IdentityConfig.store.devise_timeout_minutes - 1).minutes.ago }

      it 'will not timeout' do
        visit root_path
        expect(page).to_not have_content(' Your session expired. Please sign in again to continue.')
      end

      it 'does not log' do
        flunk
      end
    end
  end
end
