require 'rails_helper'

feature 'Home' do
  context 'when viewing the home page' do
    scenario 'you should see intro and links to dev docs and partners' do
      visit root_path

      expect(page).to have_content(I18n.t('home.body_intro'))
      expect(page).to have_content(I18n.t('home.dev_docs_link'))
      expect(page).to have_content(I18n.t('home.partners_link'))
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
