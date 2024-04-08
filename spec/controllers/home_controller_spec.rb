require 'rails_helper'

describe HomeController do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:restricted_ic) }
  let(:org) { create(:team) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    sign_in user
  end

  describe '#index' do
    context 'when the user is signed in' do
      it 'has a redirect response' do
        get :index
        expect(response.status).to eq(200)
      end
    end

    context 'when the user is not signed in' do
      before do
        allow(controller).to receive(:current_user).and_return(nil)
        sign_out user
      end

      it 'has a success response' do
        get :index
        expect(response.status).to eq(200)
      end
    end
  end
end
