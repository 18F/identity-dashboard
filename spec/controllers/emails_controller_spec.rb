require 'rails_helper'

describe EmailsController do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe '#index' do
    context 'when the user is not an admin' do
      it 'results in a 401 response' do
        get :index
        expect(response.status).to eq(401)
      end
    end

    context 'when the user is an admin' do
      before do
        allow(controller).to receive(:authorize).and_return(nil)
      end

      it 'results in a success response' do
        get :index
        expect(response.status).to eq(200)
      end
    end

    it 'requires user to be signed in' do
      allow(controller).to receive(:current_user).and_return(nil)
      get :index
      expect(response.status).to eq(401)
    end
  end
end
