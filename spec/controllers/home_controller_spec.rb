require 'rails_helper'

describe HomeController do
  include Devise::Test::ControllerHelpers

  describe '#index' do
    context 'when the user is an admin' do
      before do
        user.admin = true
      end

      it 'has a success response' do
        get :new
        expect(response.status).to eq(200)
      end
    end
    context 'when the user is not an admin' do
      it 'has an error response' do
        get :new
        expect(response.status).to eq(401)
      end
    end
  end
end
