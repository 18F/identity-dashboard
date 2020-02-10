require 'rails_helper'

describe EnvController do
  include Devise::Test::ControllerHelpers
  WebMock.allow_net_connect!

  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe '#index' do
    it 'has a success response' do
      get :index
      expect(response.status).to eq(200)
    end
  end
end
