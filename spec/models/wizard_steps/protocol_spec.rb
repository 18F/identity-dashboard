require 'rails_helper'
RSpec.describe WizardSteps::ProtocolStep do
  describe '.fields' do
    it 'returns the expected fields' do
      expect(described_class.fields).to eq(
        {
          identity_protocol: ServiceProvider.identity_protocols.keys.first,
        },
      )
    end
  end

  describe '.step_name' do
    it 'returns "protocol"' do
      expect(described_class.step_name).to eq 'protocol'
    end
  end
end
