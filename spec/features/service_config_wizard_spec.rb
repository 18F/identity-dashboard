require 'rails_helper'

feature 'Service Config Wizard' do
  let(:team) { create(:team) }
  let(:user) { create(:user, admin: false) }
  let(:admin) { create(:user, admin: true, group_id: team.id) }

  context 'as admin' do
    before do
      login_as(admin)
    end

    it 'can remember something filled in' do
      app_name = "name#{rand(1..1000)}"
      test_name = "Test name #{rand(1..1000)}"
      visit new_service_config_wizard_path
      click_on 'Next' # Skip the intro page
      current_step = find('.step-indicator__step--current')
      expect(current_step.text).to match(t('service_provider_form.wizard_steps.settings'))
      fill_in('App name', with: app_name)
      fill_in('Friendly name', with: test_name)
      click_on 'Next'
      current_step = find('.step-indicator__step--current')
      expect(current_step.text).to match(t('service_provider_form.wizard_steps.authentication'))
        click_on 'Back'
      current_step = find('.step-indicator__step--current')
      expect(current_step.text).to match(t('service_provider_form.wizard_steps.settings'))
      expect(find('#wizard_step_friendly_name').value).to eq(test_name)
    end

    it 'has the correct default options selected while walking through all steps' do
      visit new_service_config_wizard_path
      click_on 'Next' # Skip the intro page
      team_field = find_field('Team')
      team_field_options = team_field.find_all('option')
      current_value = team_field.value
      team_options_with_current_value = team_field_options.select do |opt|
        opt.value == current_value
      end
      expect(team_field_options.count).to_not eq(1)
      expect(team_options_with_current_value.count).to eq(1)
      expect(team_options_with_current_value[0].text).to eq('- Select -')
      fill_in('App name', with: 'my-app')
      fill_in('Friendly name', with: 'My App')
      team_field = find_field('Team')
      expect(team_field.value).to eq(admin.group_id.to_s)
      click_on 'Next'
      choose 'SAML'
      click_on 'Next'
      fill_in('Issuer', with: 'test:saml:issuer')
      click_on 'Next'
      click_on 'Next' # Skip logo upload for now
      encryption_field = find_field('SAML Assertion Encryption')
      expected_text = ServiceProvider.block_encryptions.keys.join(' ')
      expect(encryption_field.text).to eq(expected_text)
      expected_key = ServiceProvider.block_encryptions.keys.last
      expect(encryption_field.value.downcase).to eq(expected_key.downcase)
      fill_in('Assertion Consumer Service URL', with: 'https://localhost')
      fill_in('Return to App URL', with: 'https://localhost')
      click_on 'Next'
      expect(find_field('Sign-in').value).to eq('blank')
      expect(find_field('Sign-up').value).to eq('blank')
      expect(find_field('Forgot password').value).to eq('blank')
      click_on 'Create app'
      expect(current_url).to eq(service_providers_url)
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
