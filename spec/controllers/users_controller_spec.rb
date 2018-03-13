require 'rails_helper'

describe UsersController do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe '#index' do
    it 'requires user to be an admin' do
      get :index
      expect(response.status).to eq(401)
    end

    it 'requires user to be signed in' do
      allow(controller).to receive(:current_user).and_return(nil)
      get :index
      expect(response.status).to eq(401)
    end
  end

  xdescribe '#edit' do
    it 'requires user to be an admin' do
      get :edit, params: { id: user.uuid }
      expect(response.status).to eq(401)
    end
  end

  xdescribe '#update' do
    it 'requires user to be an admin' do
      patch :update, params: { id: user.uuid, user: { admin: 'true' } }
      expect(response.status).to eq(401)
    end
  end
end
