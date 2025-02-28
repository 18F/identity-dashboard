require 'rails_helper'
require 'axe-rspec'

feature 'User pages', :js do
  context 'when a login.gov admin' do
    let(:logingov_admin) { create(:logingov_admin) }

    before { login_as(logingov_admin) }

    context 'all_users view' do
      scenario 'is accessible' do
        visit users_path
        expect_page_to_have_no_accessibility_violations(page)
      end
    end

    context 'new_user view' do
      scenario 'is accessible' do
        visit new_user_path
        expect_page_to_have_no_accessibility_violations(page)
      end
    end

    context 'edit_user view' do
      scenario 'is accessible' do
        user = create(:user)
        visit edit_user_path(user)
        expect_page_to_have_no_accessibility_violations(page)
      end
    end
  end

  context 'when not a login.gov admin' do
    # these are unauthorized views, but we should ensure that error
    # views pass accessibility tests
    let(:user) { create(:user) }

    before { login_as(user) }

    context 'all_users view' do
      scenario 'is accessible' do
        visit users_path
        expect_page_to_have_no_accessibility_violations(page)
      end
    end

    context 'new_user view' do
      scenario 'is accessible' do
        visit new_user_path
        expect_page_to_have_no_accessibility_violations(page)
      end
    end

    context 'edit_user view' do
      scenario 'is accessible' do
        visit edit_user_path(user)
        expect_page_to_have_no_accessibility_violations(page)
      end
    end
  end
end
