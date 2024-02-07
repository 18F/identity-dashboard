require 'rails_helper'

describe 'Users::ServiceProviders' do
  describe 'approve on update' do
    it 'disallows app owner from approving the app' do
      app = create(:service_provider)
      login_as(app.user)

      put service_provider_path(app), params: { service_provider: { approved: 'true' } }

      expect(response.status).to eq(401)
    end

    it 'disallows non owner from approving the app' do
      app = create(:service_provider)
      user = create(:user)
      login_as(user)

      put service_provider_path(app), params: { service_provider: { approved: 'true' } }

      expect(response.status).to eq(401)
    end
  end

  describe 'view an app' do
    it 'allows owner to view' do
      app = create(:service_provider)
      login_as(app.user)

      get service_provider_path(app)

      expect(response.status).to eq(200)
    end

    it 'disallows non-owner from viewing' do
      user = create(:user)
      app = create(:service_provider)
      login_as(user)

      get service_provider_path(app)

      expect(response.status).to eq(401)
    end

    it 'permits admin to view' do
      admin_user = create(:user, admin: true)
      app = create(:service_provider, :with_team)
      login_as(admin_user)

      get service_provider_path(app)

      expect(response.status).to eq(200)
    end
  end
end
