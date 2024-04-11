require 'rails_helper'

feature 'Service provider pages', :js do
  before do
    allow(IdentityConfig.store).to receive(:logo_upload_enabled).and_return(false)
  end

  context 'for admins' do
    scenario 'all service providers page is accessible' do
      admin = create(:admin)
      login_as(admin)

      visit service_providers_all_path
      expect(page).to be_accessible
    end
  end

  context 'for users' do
    let(:user) { create(:user, :with_teams) }

    before do
      login_as(user)
    end

    scenario 'index page is accessible' do
      visit service_providers_path
      expect(page).to be_accessible
    end

    scenario 'new service provider page is accessible' do
      visit new_service_provider_path
      expect(page).to be_accessible
    end

    scenario 'service provider details page is accessible' do
      app = create(:service_provider, :with_users_team, user: user, logo: 'generic.svg')
      login_as(user)

      visit service_provider_path(app)
      expect(page).to be_accessible
    end

    scenario 'service provider details edit page is accessible' do
      app = create(:service_provider, :with_users_team, user: user)
      login_as(user)

      visit edit_service_provider_path(app)
      expect(page).to be_accessible
    end
  end
end
