require 'rails_helper'

feature 'Nav links' do
  context 'when login.gov admin' do
    let(:logingov_admin) { create(:user, :logingov_admin) }

    before { login_as(logingov_admin) }

    scenario 'should see manage user teams link' do
      visit service_providers_path

      expect(page).to have_content('Teams')
    end

    scenario 'should see a manage users link' do
      visit service_providers_path

      expect(page).to have_content('Users')
    end

    scenario 'should see a security events link' do
      visit service_providers_path

      expect(page).to have_content('Security Events')
    end
  end

  context 'when not login.gov admin' do
    scenario 'user should see manage user teams link' do
      user = create(:user)

      login_as(user)
      visit service_providers_path

      expect(page).to have_content('Teams')
    end

    scenario 'user should not see a manage users link' do
      user = create(:user)

      login_as(user)
      visit service_providers_path

      expect(page).to_not have_content('Users')
    end

    scenario 'user should see a security events link' do
      user = create(:user)

      login_as(user)
      visit service_providers_path

      expect(page).to_not have_content('Security Events')
    end
  end
end
