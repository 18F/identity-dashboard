require 'rails_helper'
require 'axe-rspec'

feature 'Config Wizard pages', :js do
  context 'when login.gov admin' do
    let(:logingov_admin) { create(:logingov_admin) }

    before { login_as(logingov_admin) }

    context 'all wizard pages are accessible' do
      # this could be in a loop, but we lose context and concurrency
      scenario 'intro page' do
        visit service_config_wizard_path('intro')
        expect_page_to_have_no_accessibility_violations(page)
      end

      scenario 'settings page' do
        visit service_config_wizard_path('settings')
        expect_page_to_have_no_accessibility_violations(page)
      end

      scenario 'authentication page' do
        visit service_config_wizard_path('authentication')
        expect_page_to_have_no_accessibility_violations(page)
      end

      scenario 'issuer page' do
        visit service_config_wizard_path('issuer')
        expect_page_to_have_no_accessibility_violations(page)
      end

      scenario 'logo_and_cert page' do
        visit service_config_wizard_path('logo_and_cert')
        expect_page_to_have_no_accessibility_violations(page)
      end

      scenario 'redirects page' do
        visit service_config_wizard_path('redirects')
        expect_page_to_have_no_accessibility_violations(page)
      end

      scenario 'help_text page' do
        visit service_config_wizard_path('help_text')
        expect_page_to_have_no_accessibility_violations(page)
      end
    end
  end

  context 'for users' do
    let(:user) { create(:user) }

    before { login_as(user) }

    context 'all wizard pages are accessible' do
      scenario 'help_text page' do
        visit service_config_wizard_path('help_text')
        expect_page_to_have_no_accessibility_violations(page)
      end
    end
  end
end
