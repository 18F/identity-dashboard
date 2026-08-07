require 'rails_helper'
RSpec.describe WizardSteps::AuthenticationStep do
  describe '.fields' do
    it 'returns the expected fields' do
      expect(described_class.fields).to eq(
        {
          attribute_bundle: [],
          default_aal: 0,
          ial: '1',
        },
      )
    end
  end

  describe '.step_name' do
    it 'returns "authentication"' do
      expect(described_class.step_name).to eq 'authentication'
    end
  end
end
