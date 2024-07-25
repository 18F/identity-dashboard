require 'rails_helper'

RSpec.describe IntegrationSetupController do
  let(:user) { create(:user, uuid: SecureRandom.uuid, admin: false) }
  let(:admin) { create(:user, uuid: SecureRandom.uuid, admin: true) }

  describe 'non-admin basic setup' do
  end
end
