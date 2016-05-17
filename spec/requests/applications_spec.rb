require 'rails_helper'

describe 'Users::Applications' do
  describe 'approve on update' do
    it 'disallows app owner from approving the app' do
      app = create(:application)
      login_as(app.user)

      put users_application_path(app), { application: { approved: 'true' } }

      expect(response.status).to eq(401)
    end
  end
end
