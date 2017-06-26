require 'rails_helper'

feature 'Nav links' do
  context 'user is admin' do
    scenario 'admin should see manage user groups link' do
      admin = create(:admin)

      login_as(admin)
      visit service_providers_path

      expect(page).to have_content(t('links.groups'))
    end

    scenario 'admin should see a manage users link' do
      admin = create(:admin)

      login_as(admin)
      visit service_providers_path

      expect(page).to have_content(t('links.users'))
    end
  end

  context 'user is not an admin' do
    scenario 'user should not see manage user group link' do
      user = create(:user)

      login_as(user)
      visit service_providers_path

      expect(page).to_not have_content(t('links.groups'))
    end

    scenario 'user should not see a manage users link' do
      admin = create(:user)

      login_as(admin)
      visit service_providers_path

      expect(page).to_not have_content(t('links.users'))
    end
  end
end
