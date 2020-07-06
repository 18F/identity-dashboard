require 'rails_helper'

feature 'Environments page', :js do
  include DeployStatusCheckerHelper

  before do
    stub_deploy_status
  end

  scenario 'is accessible' do
    user = create(:user)

    login_as(user)
    visit env_path
    expect(page).to be_accessible
  end
end
