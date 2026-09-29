require 'rails_helper'
RSpec.describe WizardSteps::RedirectsStep do
  describe '.fields' do
    it 'returns the expected fields' do
      expect(described_class.fields).to eq(
        {
          acs_url: '',
          assertion_consumer_logout_service_url: '',
          block_encryption: ServiceProvider.block_encryptions.keys.last,
          failure_to_proof_url: '',
          post_idv_follow_up_url: nil,
          push_notification_url: '',
          redirect_uris: [],
          return_to_sp_url: '',
          signed_response_message_requested: true,
          sp_initiated_login_url: '',
        },
      )
    end
  end

  describe '.step_name' do
    it 'returns "redirects"' do
      expect(described_class.step_name).to eq 'redirects'
    end
  end
end
