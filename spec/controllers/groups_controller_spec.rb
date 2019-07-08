require 'rails_helper'

describe GroupsController do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:org) { create(:group) }

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
    context 'when the user is signed in' do

      context 'when the user is an admin' do
        before do
          user.admin = true
        end

        it 'has a success response' do
          get :index
          expect(response.status).to eq(200)
        end
      end
    end

    context 'when the user is not an admin' do
      before do
        user.admin = false
      end

      it 'has an error response' do
        get :index
        expect(response.status).to eq(401)
      end
    end

    context 'when the user is not signed in' do
      before do
        allow(controller).to receive(:current_user).and_return(nil)
      end

      it 'has an error response' do
        get :index
        expect(response.status).to eq(401)
      end
    end
  end

  describe '#create' do
    context 'when the user is not an admin' do
      it 'has an error response' do
        post :create
        expect(response.status).to eq(401)
      end
    end

    context 'when the user is an admin' do
      before do
        user.admin = true
      end

      context 'when it creates successfully' do
        it 'has a redirect response' do
          post :create, params: {group: {name: "unique name"} }
          expect(response.status).to eq(302)
        end
      end
      context 'when it fails to create' do
        it 'renders #new' do
          post :create, params: { group: { name: '' } }
          expect(response).to render_template(:new)
        end
      end
    end
  end

  describe '#destroy' do
    context 'when the user is an admin' do
      before do
        user.admin = true
      end

      it 'has a redirect response' do
        delete :destroy, params: { id: org.id }
        expect(response.status).to eq(302)
      end
    end
    context 'when the user is not an admin'
      it 'has an error response' do
        delete :destroy, params: { id: org.id }
        expect(response.status).to eq(401)
      end
  end

  describe '#edit' do
    it 'requires user to be an admin' do
      get :edit, params: { id: org.id }
      expect(response.status).to eq(401)
    end
  end

  describe '#update' do
    context 'when the user is an admin' do
      before do
        user.admin = true
      end

      context 'when the update is successful' do
        it 'has a redirect response' do
          patch :update, params: { id: org.id, group: {name: org.name} }
          expect(response.status).to eq(302)
        end
      end

      context 'when the update is unsuccessful' do
        before do
          allow_any_instance_of(Group).to receive(:update).and_return(false)
        end

        it 'renders the edit action' do
          patch :update, params: { id: org.id, group: {name: 4} }
          expect(response).to render_template(:edit)
        end
      end
    end
    context 'when the user is not an admin' do
      it 'has an error response' do
        patch :update, params: { id: org.id }
        expect(response.status).to eq(401)
      end
    end
  end
end
