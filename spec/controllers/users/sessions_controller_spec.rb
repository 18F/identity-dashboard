require 'rails_helper'

describe Users::SessionsController do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }

  describe '#destroy' do
    before do
      request.env['devise.mapping'] = Devise.mappings[:user]
    end

    let(:uuid) { '123-asdf-qwerty' }
    let(:omniauth_hash) do
      {
        'info' => {
          'email' => user.email,
          'uuid' => uuid,
        },
        'credentials' => {
          'id_token' => 'abc123',
        },
      }
    end
    let(:logout_utility) do
      OmniAuth::LoginDotGov::LogoutUtility.new(end_session_endpoint: 'http://localhost:3000')
    end

    context 'when logged in' do
      before do
        session[:id_token] = '33939'
        allow(controller).to receive(:current_user).and_return(user)
        allow(controller.class).to receive(:logout_utility).and_return(logout_utility)
        sign_in user
      end

      it 'logs user out' do
        get :destroy
        expect(response.location).to match('http://localhost:3000')
        expect(response).to have_http_status :found
      end
    end

    context 'when logged out' do
      it 'redirects to the empty user path' do
        get :destroy
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
