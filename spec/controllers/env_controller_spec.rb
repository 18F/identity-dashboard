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
    it 'has a success response on lower envs' do
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return(false)
      get :index
      expect(response).to have_http_status(:ok)
    end

    it 'has a 404 response on prod-like envs' do
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
      get :index
      expect(response).to have_http_status(404)
    end
  end
end
