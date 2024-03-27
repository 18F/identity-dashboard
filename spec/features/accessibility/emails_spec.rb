require 'rails_helper'
require 'axe-rspec'

feature 'Email pages', :js do
  let(:admin) { create(:admin) }

  scenario 'unauthorized user page is accessible' do
    visit emails_path
    expect_page_to_have_no_accessibility_violations(page)
  end


  scenario 'index page is accessible' do
    login_as(admin)

    visit emails_path
    expect_page_to_have_no_accessibility_violations(page)
  end
end
