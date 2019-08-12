require 'rails_helper'

describe UsersController do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe '#new' do
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

  describe '#index' do
    context 'when the user is an admin' do
      before do
        user.admin = true
      end

      it 'has a success response' do
        get :index
        expect(response.status).to eq(200)
      end
    end
    context 'when the user is not an admin' do
      it 'has an error response' do
        get :index
        expect(response.status).to eq(401)
      end
    end
  end

  describe '#edit' do
    context 'when the user is an admin' do
      before do
        user.admin = true
      end

      it 'has a success response' do
        get :edit, params: { id: 1 }
        expect(response.status).to eq(200)
      end
    end
    context 'when the user is not an admin' do
      it 'has an error response' do
        get :edit, params: { id: 1 }
        expect(response.status).to eq(401)
      end
    end
  end

  describe '#update' do
    context 'when the user is an admin' do
      before do
        user.admin = true
      end

      it 'has a redirect response' do
        patch :update, params: { id: user.id, user: { admin: true, email: 'example@example.com' } }
        expect(response.status).to eq(302)
      end
    end
    context 'when the user is not an admin' do
      it 'has an error response' do
        patch :update, params: { id: user.id, user: { admin: true, email: 'example@example.com' } }
        expect(response.status).to eq(401)
      end
    end
  end

  describe '#create' do
    context 'when the user is an admin' do
      before do
        user.admin = true
      end

      context 'when the user is valid' do
        it 'has a redirect response' do
          patch :create, params: { user: { admin: true, email: 'example@example.com' } }
          expect(response.status).to eq(302)
        end
      end
      context 'when the user is invalid' do
        it "renders the 'new' view" do
          patch :create, params: { user: { admin: true, email: user.email } }
          expect(response).to render_template(:new)
        end
      end
    end
    context 'when the user is not an admin' do
      it 'has an error response' do
        patch :create, params: { user: { admin: true, email: 'example@example.com' } }
        expect(response.status).to eq(401)
      end
    end
  end

  describe '#none' do
    it 'overrides the CSP for the embedded HubSpot form' do
      get :none
      csp = response.request.headers.env['secure_headers_request_config'].csp

      expect(csp.script_src).to eq(["*.hsforms.net", "*.hsforms.com", "\'self\'"])
      expect(csp.style_src).to eq(["\'self\'", "\'unsafe-inline\'"])
      expect(csp.img_src).to eq(["*.hsforms.com", "*.hsforms.net", "\'self\'"])
    end
  end
end
