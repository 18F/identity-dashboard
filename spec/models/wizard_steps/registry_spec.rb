require 'rails_helper'
RSpec.describe WizardSteps::Registry do
  describe '#step_classes' do
    it 'returns the ordered list of steps' do
      expect(described_class.step_classes).to eq(
        [
          WizardSteps::IntroStep,
          WizardSteps::SettingsStep,
          WizardSteps::ProtocolStep,
          WizardSteps::AuthenticationStep,
          WizardSteps::IssuerStep,
          WizardSteps::LogoAndCertStep,
          WizardSteps::RedirectsStep,
          WizardSteps::HelpTextStep,
          WizardSteps::HiddenStep,
        ],
      )
    end
  end
end
