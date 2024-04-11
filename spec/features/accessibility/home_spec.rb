require 'rails_helper'

feature 'Home page', :js do
  scenario 'is accessible' do
    user = create(:user)

    login_as(user)
    visit root_path

    expect(page).to be_accessible
  end
end
