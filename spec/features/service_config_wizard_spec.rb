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
      all_but_last_step = ServiceConfigWizardController::STEPS[0...-1]
      all_but_last_step.each do |step|
        expect(body).to match(t("service_provider_form.wizard_steps.#{step}"))
        click_on 'Next'
      end
    end
  end

  context 'as a non-admin' do
    before do
      login_as(user)
    end

    it 'is redirected to service_providers if not flagged in' do
      expect(IdentityConfig.store).to receive(:service_config_wizard_enabled).
        at_least(ServiceConfigWizardController::STEPS.count + 1).
        and_return(nil)
      visit new_service_config_wizard_path
      expect(current_url).to eq(service_providers_url)
      ServiceConfigWizardController::STEPS.each do |step|
        visit new_service_config_wizard_path(step)
        expect(current_url).to eq(service_providers_url)
      end
    end
  end
end
