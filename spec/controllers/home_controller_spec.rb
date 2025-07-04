require 'rails_helper'

describe HomeController do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:org) { create(:team) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    sign_in user
  end

  describe '#index' do
    context 'when the user is signed in' do
      it 'has a redirect response' do
        get :index
        expect(response).to have_http_status(:ok)
      end

      it 'sets canonical url' do
        get :index
        expect(assigns(:canonical_url)).to be_nil
      end
    end

    context 'when the user is not signed in' do
      before do
        allow(controller).to receive(:current_user).and_return(nil)
        sign_out user
      end

      it 'has a success response' do
        get :index
        expect(response).to have_http_status(:ok)
      end

      it 'sets canonical url' do
        get :index
        expect(assigns(:canonical_url)).to_not be_empty
      end
    end
  end

  describe '#system_use' do
    context 'when the user is signed in' do
      it 'has a redirect response' do
        get :system_use
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the user is not signed in' do
      before do
        allow(controller).to receive(:current_user).and_return(nil)
        sign_out user
      end

      it 'has a success response' do
        get :system_use
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
