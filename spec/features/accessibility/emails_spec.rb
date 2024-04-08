require 'rails_helper'
require 'axe-rspec'

feature 'Email pages', :js do
  let(:user) { create(:restricted_ic) }

  context 'emails index page' do
    before do
      login_as(user)
      visit emails_path
    end

    context 'with an unauthorized user' do
      scenario 'error page is accessible' do
        expect_page_to_have_no_accessibility_violations(page)
      end
    end

    context 'with an admin user' do
      let(:user) { create(:admin) }
      scenario 'is accessible' do
        expect_page_to_have_no_accessibility_violations(page)
      end
    end
  end
end
