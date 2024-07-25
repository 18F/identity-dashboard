require 'rails_helper'

feature 'Integration Setup Wizard' do
  let(:user) { create(:user, admin: false) }
  let(:admin) { create(:user, admin: true) }

  context 'as admin' do
    before do
      login_as(admin)
    end

    it 'can step through all the pages' do
      visit new_integration_setup_path
      IntegrationSetupController::STEPS.each do |step|
        expect(body).to match(step.to_s)
        click_on 'Next'
      end
    end
  end

  context 'as a non-admin' do
    before do
      login_as(user)
    end

    it 'is not currently authorized' do
      visit new_integration_setup_path
      expect(status_code).to be(401)
      IntegrationSetupController::STEPS.each do |step|
        visit new_integration_setup_path(step)
        expect(status_code).to be(401)
      end
    end
  end
end
