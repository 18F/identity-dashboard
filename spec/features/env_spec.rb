require 'rails_helper'

feature 'Environemnts' do
  include DeployStatusCheckerHelper

  before do
    stub_deploy_status
  end

  context 'any user viewing the environemnts page' do
    scenario 'should see prod, staging, int and dev environments' do
      user = create(:user)

      login_as(user)
      visit env_path

      expect(page).to have_content('Production')
      expect(page).to have_content('Staging')
      expect(page).to have_content('Agency integration')
      expect(page).to have_content('Development')
    end
  end
end
