require 'rails_helper'
require 'axe-rspec'

feature 'Home page', :js do
  scenario 'is accessible' do
    user = create(:user)

    login_as(user)
    visit root_path

    expect_page_to_have_no_accessibility_violations(page)
  end
end
