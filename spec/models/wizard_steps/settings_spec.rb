require 'rails_helper'
RSpec.describe WizardSteps::SettingsStep do
  describe '.fields' do
    it 'returns the expected fields' do
      expect(described_class.fields).to eq(
        {
          app_name: '',
          description: '',
          friendly_name: '',
          group_id: nil,
          prod_config: false,
        },
      )
    end
  end

  describe '.step_name' do
    it 'returns "settings"' do
      expect(described_class.step_name).to eq 'settings'
    end
  end
end
