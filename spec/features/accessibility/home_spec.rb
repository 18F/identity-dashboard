require 'rails_helper'
require 'axe-rspec'

feature 'Home page', :js do
  context 'as a logged in user' do
    scenario 'is accessible' do
      user = create(:restricted_ic)

      login_as(user)
      visit root_path

      expect_page_to_have_no_accessibility_violations(page)
    end
  end

  context 'not logged in user' do
    scenario 'is accessible' do
      visit root_path

      expect_page_to_have_no_accessibility_violations(page)
    end
  end
end
