require 'rails_helper'

feature 'Service Config Wizard' do
  let(:user) { create(:user, admin: false) }
  let(:admin) { create(:user, admin: true) }

  context 'as admin' do
    before do
      login_as(admin)
    end

    it 'can step through all the pages' do
      visit new_service_config_wizard_path
      ServiceConfigWizardController::STEPS.each do |step|
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
      visit new_service_config_wizard_path
      expect(status_code).to be(401)
      ServiceConfigWizardController::STEPS.each do |step|
        visit new_service_config_wizard_path(step)
        expect(status_code).to be(401)
      end
    end
  end
end
