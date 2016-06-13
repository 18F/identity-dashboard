require 'rails_helper'

describe 'Users::Applications' do
  describe 'approve on update' do
    it 'disallows app owner from approving the app' do
      app = create(:application)
      login_as(app.user)

      put users_application_path(app), application: { approved: 'true' }

      expect(response.status).to eq(401)
    end

    it 'disallows non owner from approving the app' do
      app = create(:application)
      user = create(:user)
      login_as(user)

      put users_application_path(app), application: { approved: 'true' }

      expect(response.status).to eq(401)
    end

    it 'allows admin to approve' do
      app = create(:application)
      admin_user = create(:user, admin: true)
      login_as(admin_user)

      put users_application_path(app), application: { approved: 'true' }

      expect(response.status).to eq(302) # redirect on success
      app.reload
      expect(app.approved?).to eq(true)
    end
  end

  describe 'view an app' do
    it 'allows owner to view' do
      app = create(:application)
      login_as(app.user)

      get users_application_path(app)

      expect(response.status).to eq(200)
    end

    it 'disallows non-owner from viewing' do
      user = create(:user)
      app = create(:application)
      login_as(user)

      get users_application_path(app)

      expect(response.status).to eq(401)
    end

    it 'permits admin to view' do
      admin_user = create(:user, admin: true)
      app = create(:application)
      login_as(admin_user)

      get users_application_path(app)

      expect(response.status).to eq(200)
    end
  end
end
