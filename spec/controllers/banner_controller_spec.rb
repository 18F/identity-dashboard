require 'rails_helper'

RSpec.describe BannersController do
  let(:user) { create(:user, uuid: SecureRandom.uuid, admin: false) }
  let(:logingov_admin) { create(:user, :logingov_admin) }
  let(:banner) { create(:banner) }

  let(:updated_message) { 'Updated Banner' }
  let(:updated_start_date) { Time.zone.today - 1.year }
  let(:updated_end_date) { Time.zone.today + 1.year }

  context 'when logged in as login.gov admin' do
    before do
      sign_in logingov_admin
    end

    it 'allows all access' do
      get :new
      expect(response).to be_successful
      get :index
      expect(response).to be_successful
      get :edit, params: { id: banner.id }
      expect(response).to be_successful
      put :create, params: { banner: { message: 'test message' } }
      expect(response).to be_redirect
      patch :update, params: banner.attributes
      expect(response).to be_redirect
    end

    describe 'create' do
      it 'redirects to the banner index' do
        allow(Banner).to receive(:new).and_return(instance_double(Banner, save: true))
        get :create, params: { banner: { message: 'test message' } }
        expect(response.redirect_url).to eq(banners_url)
      end
    end

    describe 'update' do
      it 'redirects to the banner index' do
        put :update, params: {
          id: banner.id,
          banner: {
            message: updated_message,
            start_date: updated_start_date,
            end_date: updated_end_date,
          },
        }
        banner.reload
        expect(banner.message).to eq(updated_message)
        expect(banner.start_date).to eq(updated_start_date)
        expect(banner.end_date).to eq(updated_end_date)
      end
    end
  end

  context 'when not logged in' do
    it 'denies all access' do
      get :new
      expect(response).to be_unauthorized
      get :index
      expect(response).to be_unauthorized
      get :edit, params: { id: banner.id }
      expect(response).to be_unauthorized
      put :create, params: { banner: { message: 'test message' } }
      expect(response).to be_unauthorized
      patch :update, params: banner.attributes
      expect(response).to be_unauthorized
    end
  end

  context 'when not logged in as login.gov admin' do
    before do
      sign_in user
    end

    it 'denies all access' do
      get :new
      expect(response).to be_unauthorized
      get :index
      expect(response).to be_unauthorized
      get :edit, params: { id: banner.id }
      expect(response).to be_unauthorized
      put :create, params: { banner: { message: 'test message' } }
      expect(response).to be_unauthorized
      patch :update, params: banner.attributes
      expect(response).to be_unauthorized
    end
  end
end
