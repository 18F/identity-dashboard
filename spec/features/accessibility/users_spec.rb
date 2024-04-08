require 'rails_helper'
require 'axe-rspec'

feature 'User pages', :js do

  context 'as an admin' do
    let(:admin) { create(:admin) }
    before { login_as(admin) }

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
        user = create(:restricted_ic)
        visit edit_user_path(user)
        expect_page_to_have_no_accessibility_violations(page)
      end
    end
  end

  context 'as a non-admin' do
    # these are unauthorized views, but we should ensure that error
    # views pass accessibility tests
    let(:user) { create(:restricted_ic) }
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
