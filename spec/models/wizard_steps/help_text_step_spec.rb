require 'rails_helper'
RSpec.describe WizardSteps::HelpTextStep do
  describe '.fields' do
    it 'returns the expected fields' do
      expect(described_class.fields).to eq(
        {
          help_text: {
            sign_in: { 'en' => '', 'es' => '', 'fr' => '', 'zh' => '' },
            sign_up: { 'en' => '', 'es' => '', 'fr' => '', 'zh' => '' },
            forgot_password: { 'en' => '', 'es' => '', 'fr' => '', 'zh' => '' },
          },
        },
      )
    end
  end

  describe '.step_name' do
    it 'returns "help_text"' do
      expect(described_class.step_name).to eq 'help_text'
    end
  end
end
