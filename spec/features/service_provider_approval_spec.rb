require 'rails_helper'

xfeature 'Service Provider approval' do
  context 'user is an admin' do
    scenario 'has option to approve service provider' do
      admin_user = create(:user, admin: true)

      login_as(admin_user)
      visit new_service_provider_path

      expect(page).to have_content('Approved')
    end
  end

  context 'user is not an admin' do
    scenario 'does not have option to approve service provider' do
      user = create(:user)

      login_as(user)
      visit new_service_provider_path

      expect(page).to_not have_content('Approved')
    end
  end
end
