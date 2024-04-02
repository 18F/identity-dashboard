require 'rails_helper'
require 'axe-rspec'

feature 'Service provider pages', :js do
  before do
    allow(IdentityConfig.store).to receive(:logo_upload_enabled).and_return(false)
  end

  context 'for admins' do
    let(:admin) { create(:admin) }
    before { login_as(admin) }

    scenario 'all service providers page is accessible' do
      visit service_providers_all_path
      expect_page_to_have_no_accessibility_violations(page)
    end

    context 'a service provider exists' do
      let(:user) { create(:user, :with_teams) }
      let(:app) { create(:service_provider, :with_users_team, user: user, logo: 'generic.svg') }

      context 'show page' do
        # admins have access to more features
        scenario 'is accessible' do
          visit service_provider_path(app)
          expect_page_to_have_no_accessibility_violations(page)
        end
      end

      context 'edit page' do
        scenario 'is accessible' do
          visit edit_service_provider_path(app)
          expect_page_to_have_no_accessibility_violations(page)
        end
      end
    end
  end

  context 'for users' do
    let(:user) { create(:user, :with_teams) }

    before { login_as(user) }

    context 'index page' do
      scenario 'accessible' do
        visit service_providers_path
        expect_page_to_have_no_accessibility_violations(page)
      end
    end

    context 'new service provide page' do
      scenario 'new service provider page' do
        visit new_service_provider_path
        expect_page_to_have_no_accessibility_violations(page)
      end
    end

    context 'service provider exists' do
      let(:app) { create(:service_provider, :with_users_team, user: user, logo: 'generic.svg') }

      context 'show page' do
        scenario 'is accessible' do
          visit service_provider_path(app)
          expect_page_to_have_no_accessibility_violations(page)
        end
      end

      context 'edit page' do
        scenario 'is accessible' do
          visit edit_service_provider_path(app)
          expect_page_to_have_no_accessibility_violations(page)
        end
      end
    end
  end
end
