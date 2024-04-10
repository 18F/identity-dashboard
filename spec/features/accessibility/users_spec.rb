require 'rails_helper'

feature 'User pages', :js do
  before do
    admin = create(:admin)
    login_as(admin)
  end

  scenario 'all users page is accessible' do
    visit users_path
    expect(page).to be_accessible
  end

  scenario 'new user page is accessible' do
    visit new_user_path
    expect(page).to be_accessible
  end

  scenario 'edit user page is accessible' do
    user = create(:user)
    visit edit_user_path(user)
    expect(page).to be_accessible
  end
end
