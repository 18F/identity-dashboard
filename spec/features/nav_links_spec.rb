require 'rails_helper'

feature 'Nav links' do
  context 'user is admin' do
    scenario 'admin should see manage user teams link' do
      admin = create(:admin)

      login_as(admin)
      visit service_providers_path

      expect(page).to have_content('Teams')
    end

    scenario 'admin should see a manage users link' do
      admin = create(:admin)

      login_as(admin)
      visit service_providers_path

      expect(page).to have_content('Users')
    end

    scenario 'admin should see a security events link' do
      admin = create(:admin)

      login_as(admin)
      visit service_providers_path

      expect(page).to have_content('Security Events')
    end
  end

  context 'user is not an admin' do
    scenario 'user should see manage user teams link' do
      user = create(:restricted_ic)

      login_as(user)
      visit service_providers_path

      expect(page).to have_content('Teams')
    end

    scenario 'user should not see a manage users link' do
      admin = create(:restricted_ic)

      login_as(admin)
      visit service_providers_path

      expect(page).to_not have_content('Users')
    end

    scenario 'user should see a security events link' do
      admin = create(:restricted_ic)

      login_as(admin)
      visit service_providers_path

      expect(page).to_not have_content('Security Events')
    end

  end
end
