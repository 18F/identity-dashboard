require 'rails_helper'
require 'axe-rspec'

feature 'User pages', :js do
  before do
    admin = create(:admin)
    login_as(admin)
  end

  scenario 'all users page is accessible' do
    visit users_path
    expect_page_to_have_no_accessibility_violations(page)
  end

  scenario 'new user page is accessible' do
    visit new_user_path
    expect_page_to_have_no_accessibility_violations(page)
  end

  scenario 'edit user page is accessible' do
    user = create(:user)
    visit edit_user_path(user)
    expect_page_to_have_no_accessibility_violations(page)
  end
end
