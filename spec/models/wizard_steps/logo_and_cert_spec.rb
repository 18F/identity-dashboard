require 'rails_helper'
RSpec.describe WizardSteps::LogoAndCertStep do
  describe '.fields' do
    it 'returns the expected fields' do
      expect(described_class.fields).to eq(
        {
          certs: [],
          logo_name: '',
          remote_logo_key: '',
        },
      )
    end
  end

  describe '.step_name' do
    it 'returns "logo_and_cert"' do
      expect(described_class.step_name).to eq 'logo_and_cert'
    end
  end
end
