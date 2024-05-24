require 'rails_helper'

RSpec.describe BannersController do
  let(:user) { create(:user, uuid: SecureRandom.uuid, admin: false) }
  let(:admin) { create(:user, uuid: SecureRandom.uuid, admin: true) }
  let(:banner) { create(:banner) }

  context 'when logged in as admin' do
    before do
      sign_in admin
    end

    it 'allows all access' do
      get :new
      expect(response).to be_successful
      get :index
      expect(response).to be_successful
      get :edit, params: {id: banner.id}
      expect(response).to be_successful
      put :create, params: { banner: { message: 'test message'}}
      expect(response).to be_redirect
      patch :update, params: banner.attributes
      expect(response).to be_redirect
    end
  end

  context 'when not logged in ' do
    it 'denies all access' do
      get :new
      expect(response).to be_unauthorized
      get :index
      expect(response).to be_unauthorized
      get :edit, params: {id: banner.id}
      expect(response).to be_unauthorized
      put :create, params: { banner: { message: 'test message'}}
      expect(response).to be_unauthorized
      patch :update, params: banner.attributes
      expect(response).to be_unauthorized
    end
  end

  context 'when not logged in as admin' do
    before do
      sign_in user
    end

    it 'denies all access' do
      get :new
      expect(response).to be_unauthorized
      get :index
      expect(response).to be_unauthorized
      get :edit, params: {id: banner.id}
      expect(response).to be_unauthorized
      put :create, params: { banner: { message: 'test message'}}
      expect(response).to be_unauthorized
      patch :update, params: banner.attributes
      expect(response).to be_unauthorized
    end  
  end
end