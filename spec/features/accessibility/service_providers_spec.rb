require 'rails_helper'
require 'axe-rspec'

feature 'Service provider pages', :js do
  context 'when login.gov admin' do
    let(:logingov_admin) { create(:logingov_admin) }

    before { login_as(logingov_admin) }

    scenario 'all service providers page is accessible' do
      visit service_providers_all_path
      expect_page_to_have_no_accessibility_violations(page)
    end

    context 'a service provider exists' do
      let(:user) { create(:user, :with_teams) }
      let(:app) { create(:service_provider, with_team_from_user: user, logo: 'generic.svg') }

      context 'show page' do
        # login.gov admins have access to more features
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
      let(:app) { create(:service_provider, with_team_from_user: user, logo: 'generic.svg') }

      context 'show page' do
        scenario 'is accessible' do
          visit service_provider_path(app)
          expect_page_to_have_no_accessibility_violations(page)
        end

        context 'with a SAML app' do
          let(:app) do
            create(:service_provider,
                   :saml,
                   with_team_from_user: user,
                   logo: 'generic.svg')
          end

          scenario 'is accessible' do
            visit service_provider_path(app)
            expect_page_to_have_no_accessibility_violations(page)
          end
        end
      end

      context 'edit page' do
        scenario 'is accessible' do
          visit edit_service_provider_path(app)
          expect_page_to_have_no_accessibility_violations(page)
        end
      end

      context 'edit page' do
        context 'switching to a a SAML app' do
          before do
            visit edit_service_provider_path(app)
            find('label[for=service_provider_identity_protocol_saml]').click
          end

          scenario 'is accessible' do
            expect_page_to_have_no_accessibility_violations(page)
          end

          context 'getting an error' do
            before do
              click_on 'Update'
            end

            scenario 'view is still accessible' do
              expect_page_to_have_no_accessibility_violations(page)
            end
          end
        end
      end
    end
  end
end
