require 'rails_helper'
require 'axe-rspec'

feature 'Security events pages', :js do
  context 'index view' do
    context 'as a logged in user' do
      before { login_as user }

      context 'when not login.gov admin' do
        let(:user) { create(:user) }

        # not authorized but should ensure accesibility
        scenario 'is accessible' do
          visit security_events_path
          expect_page_to_have_no_accessibility_violations(page)
        end
      end

      context 'admin user' do
        let(:user) { create(:user, :logingov_admin) }

        scenario 'is accessible' do
          visit security_events_path
          expect_page_to_have_no_accessibility_violations(page)
        end

        context 'when there are RISC events in the table' do
          before do
            create_list(:security_event, 4, user:)
          end

          scenario 'is accessible' do
            visit security_events_path
            expect_page_to_have_no_accessibility_violations(page)
          end
        end
      end
    end

    context 'not logged in user' do
      scenario 'is accessible' do
        visit security_events_path
        expect_page_to_have_no_accessibility_violations(page)
      end
    end
  end

  context 'all security events view' do
    # Events need a user
    let(:user) { create(:user) }

    context 'as a logged in user' do
      before { login_as user }

      context 'when not login.gov admin' do
        # not authorized but should ensure accesibility
        scenario 'is accessible' do
          visit security_events_all_path
          expect_page_to_have_no_accessibility_violations(page)
        end
      end

      context 'when login.gov admin' do
        before { login_as create(:user, :logingov_admin) }

        scenario 'is accessible' do
          visit security_events_all_path
          expect_page_to_have_no_accessibility_violations(page)
        end

        context 'when there are RISC events in the table' do
          before do
            create_list(:security_event, 4, user:)
          end

          scenario 'is accessible' do
            visit security_events_all_path
            expect_page_to_have_no_accessibility_violations(page)
          end
        end
      end
    end

    context 'not logged in user' do
      scenario 'is accessible' do
        visit security_events_all_path
        expect_page_to_have_no_accessibility_violations(page)
      end
    end
  end

  context 'individual security events show view' do
    let(:user) { create(:user) }
    let(:event) { create(:security_event, user:) }

    context 'as a logged in user' do
      before { login_as user }

      context 'when not login.gov admin' do
        # not authorized but should ensure accesibility
        scenario 'is accessible' do
          visit security_event_path(event)
          expect_page_to_have_no_accessibility_violations(page)
        end
      end

      context 'when login.gov admin' do
        let(:user) { create(:user, :logingov_admin) }

        scenario 'is accessible' do
          visit security_event_path(event)
          expect_page_to_have_no_accessibility_violations(page)
        end
      end

    end

    context 'not logged in user' do
      scenario 'is accessible' do
        visit security_event_path(event)
        expect_page_to_have_no_accessibility_violations(page)
      end
    end
  end
end
