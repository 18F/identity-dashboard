require 'rails_helper'

describe EnvController do
  include Devise::Test::ControllerHelpers
  include DeployStatusCheckerHelper

  let(:user) { create(:user) }

  before do
    stub_deploy_status
    allow(controller).to receive(:current_user).and_return(user)
    sign_in user
  end

  describe '#index' do
    it 'has a success response' do
      get :index
      expect(response).to have_http_status(:ok)
    end
  end
end
