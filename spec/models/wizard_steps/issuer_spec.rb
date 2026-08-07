require 'rails_helper'
RSpec.describe WizardSteps::IssuerStep do
  describe '.fields' do
    it 'returns the expected fields' do
      expect(described_class.fields).to eq(
        {
          issuer: '',
        },
      )
    end
  end

  describe '.step_name' do
    it 'returns "issuer"' do
      expect(described_class.step_name).to eq 'issuer'
    end
  end
end
