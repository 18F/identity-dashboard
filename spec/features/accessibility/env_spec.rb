require 'rails_helper'
require 'axe-rspec'

feature 'Environments page', :js do
  include DeployStatusCheckerHelper

  before do
    stub_deploy_status
  end

  scenario 'is accessible' do
    user = create(:user)

    login_as(user)
    visit env_path
    expect_page_to_have_no_accessibility_violations(page)
  end
end
