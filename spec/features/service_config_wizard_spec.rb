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
      ServiceConfigWizardController::STEPS.each_with_index do |step, index|
        current_step = find('.step-indicator__step--current')
        expect(current_step.text).to match(t("service_provider_form.wizard_steps.#{step}"))
        completed_steps = find_all('.step-indicator__step--complete')
        expect(completed_steps.count).to be(index)
        click_on 'Next' unless step == ServiceConfigWizardController::STEPS[-1]
      end
    end

    it 'can remember something filled in' do
      test_name = "Test name #{rand(1..1000)}"
      visit new_service_config_wizard_path
      click_on 'Next' # Skip the intro page
      current_step = find('.step-indicator__step--current')
      expect(current_step.text).to match(t('service_provider_form.wizard_steps.settings'))
      fill_in('Friendly name', with: test_name)
      click_on 'Next'
      current_step = find('.step-indicator__step--current')
      expect(current_step.text).to match(t('service_provider_form.wizard_steps.authentication'))
        click_on 'Back'
      current_step = find('.step-indicator__step--current')
      expect(current_step.text).to match(t('service_provider_form.wizard_steps.settings'))
      expect(find('#wizard_step_friendly_name').value).to eq(test_name)
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
