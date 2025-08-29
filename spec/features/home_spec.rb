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
      click_on 'Admin'
      api_auth_link = find_link 'Your API auth token'
      expect(api_auth_link['href']).to eq(auth_tokens_path)
      user_csv_link = find_link 'User permissions report'
      expect(user_csv_link['href']).to eq(internal_reports_team_memberships_path(format: 'csv'))
    end
  end

  context 'a user who is not an admin' do
    scenario 'should see manage teams and not see manage users' do
      user = create(:user)

      login_as(user)
      visit root_path

      expect(page).to have_content('Teams')
      expect(page).to_not have_content('Users')
      expect(page).to_not have_content('Admin')
      expect(page).to_not have_content('API auth')
      expect(page).to_not have_content('permissions report')
    end
  end

  context 'prod_like_env' do
    before do
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
    end

    context 'a user who is a login_admin in prod_like_env' do
      let(:logingov_admin) { create(:user, :logingov_admin) }


      scenario 'should see create team button' do
        login_as(logingov_admin)
        visit root_path

        expect(page).to have_content('Create your first team')
      end
    end

    context 'a user who is not a login_admin in prod_like_env' do
      scenario 'should not see create team button' do
        user = create(:user)

        login_as(user)
        visit root_path

        expect(page).to_not have_content('Create a new team')
        expect(page).to_not have_content('Create your first team')
      end
    end

    scenario 'is logged out after Devise timeout' do
      expect(user.timedout?(IdentityConfig.store.devise_timeout_minutes.minutes.ago)).to be_truthy
    end
  end
end
