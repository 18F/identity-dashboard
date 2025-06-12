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
      click_on (I18n.t('links.sign_in'))

      expect(page).to have_content(I18n.t('home.system_use'))
      expect(page).to have_content(I18n.t('home.system_agree'))
      expect(page).to have_css('[action="/auth/logindotgov"]')
    end
  end

  context 'when login.gov admin' do
    scenario 'should see manage teams and manage users' do
      logingov_admin = create(:user, :logingov_admin)

      login_as(logingov_admin)
      visit root_path

      expect(page).to have_content('Teams')
      expect(page).to have_content('Users')
    end
  end

  context 'a user who is not an admin' do
    scenario 'should see manage teams and not see manage users' do
      user = create(:user)

      login_as(user)
      visit root_path

      expect(page).to have_content('Teams')
      expect(page).to_not have_content('Users')
    end
  end
end
