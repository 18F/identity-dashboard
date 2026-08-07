require 'rails_helper'
RSpec.describe WizardSteps::HiddenStep do
  describe '.fields' do
    it 'returns the expected fields' do
      expect(described_class.fields).to eq(
        {
          active: false,
          agency_id: nil,
          allow_prompt_login: false,
          approved: false,
          email_nameid_format_allowed: nil,
          metadata_url: nil,
          service_provider_id: nil,
          service_provider_user_id: nil,
        },
      )
    end
  end

  describe '.step_name' do
    it 'returns "hidden"' do
      expect(described_class.step_name).to eq 'hidden'
    end
  end
end
