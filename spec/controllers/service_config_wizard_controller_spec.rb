require 'rails_helper'
require 'pry'

RSpec.describe ServiceConfigWizardController do
  let(:user) { create(:user, uuid: SecureRandom.uuid, admin: false) }
  let(:admin) { create(:user, uuid: SecureRandom.uuid, admin: true) }

  def flag_in
    expect(IdentityConfig.store).to receive(:service_config_wizard_enabled).and_return(true)
  end

  def flag_out
    expect(IdentityConfig.store).to receive(:service_config_wizard_enabled).and_return(false)
  end

  context 'as an admin' do
    before do
      sign_in admin
    end

    it 'can start the first step' do
      flag_in
      get :new
      expect(response).to be_redirect
      expect(response.redirect_url).to eq(service_config_wizard_url(Wicked::FIRST_STEP))
    end

    it 'can get all steps' do
      ServiceConfigWizardController::STEPS.each do |wizard_step|
        get :show, params: {id: wizard_step}
        expect(response).to be_ok
        expect(assigns[:model].step_name).to eq(wizard_step)
      end
    end

    it 'can post all steps' do
      ServiceConfigWizardController::STEPS.each_with_index do |wizard_step, index|
        get :update, params: {id: wizard_step, wizard_step: {active: false}}
        expect(response).to be_redirect
        next_step = ServiceConfigWizardController::STEPS[index + 1]
        expect(response.redirect_url).to eq(service_config_wizard_url(next_step)) if next_step
      end
    end

    it 'allows blank info for the logo_and_cert step for now' do
      get :update, params: {id: 'logo_and_cert'}
      expect(response).to be_redirect
      next_index = ServiceConfigWizardController::STEPS.index('logo_and_cert') + 1
      next_step = ServiceConfigWizardController::STEPS[next_index]
      expect(response.redirect_url).to eq(service_config_wizard_url(next_step))
    end

    it 'will wipe all step data if the user cancels on the last step' do
      create(:wizard_step, user: admin, data: { help_text: {'sign_in' => 'blank'}})
      expect do
        get :update, params: {id: ServiceConfigWizardController::STEPS.last, commit: 'Cancel'}
      end.to(change {WizardStep.count}.by(-1))
      expect(response.redirect_url).to eq(service_providers_url)
    end

    it 'will be redirected if the flag is not set' do
      flag_out
      get :new
      expect(response).to be_redirect
      expect(response.redirect_url).to eq(service_providers_url)
    end
  end

  context 'as a non-admin user' do
    before do
      sign_in user
    end

    it 'can start the first step' do
      flag_in
      get :new
      expect(response).to be_redirect
      expect(response.redirect_url).to eq(service_config_wizard_url(Wicked::FIRST_STEP))
    end

    it 'will be redirected if the flag is not set' do
      flag_out
      get :new
      expect(response).to be_redirect
      expect(response.redirect_url).to eq(service_providers_url)
    end
  end

  context 'when not logged in' do
    it 'requires authentication without checking flag status' do
      expect(IdentityConfig.store).to receive(:service_config_wizard_enabled).never
      get :new
      expect(response).to be_redirect
      expect(response.redirect_url).to eq(root_url)
    end
  end
end
