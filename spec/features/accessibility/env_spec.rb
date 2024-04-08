require 'rails_helper'
require 'axe-rspec'

feature 'Environments page', :js do
  include DeployStatusCheckerHelper

  before do
    stub_deploy_status
  end

  context 'as a logged in user' do
    scenario 'is accessible' do
      user = create(:restricted_ic)

      login_as(user)
      visit env_path
      expect_page_to_have_no_accessibility_violations(page)
    end
  end

  context 'not logged in' do
    scenario 'is accessible' do
      visit env_path
      expect_page_to_have_no_accessibility_violations(page)
    end
  end
end
