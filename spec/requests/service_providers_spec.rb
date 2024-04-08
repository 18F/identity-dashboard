require 'rails_helper'

describe 'Users::ServiceProviders' do
  let(:sp) { create(:service_provider, :with_team) }
  let(:user) { create(:restricted_ic) }
  let(:admin_user) { create(:admin) }
  describe 'approve on update' do
    it 'disallows app owner from approving the app' do
      login_as(sp.user)

      put service_provider_path(sp), params: { service_provider: { approved: 'true' } }

      expect(response.status).to eq(401)
    end

    it 'disallows non owner from approving the app' do
      login_as(user)

      put service_provider_path(sp), params: { service_provider: { approved: 'true' } }

      expect(response.status).to eq(401)
    end


    it 'allows admin to approve' do
      login_as(admin_user)

      put service_provider_path(sp), params: { service_provider: { approved: 'true' } }

      expect(response.status).to eq(302)  # redirect on success
      sp.reload
      expect(sp.approved).to eq(true)
    end
  end

  describe 'view an app' do
    it 'allows owner to view' do
      login_as(sp.user)

      get service_provider_path(sp)

      expect(response.status).to eq(200)
    end

    it 'disallows non-owner from viewing' do
      login_as(user)

      get service_provider_path(sp)

      expect(response.status).to eq(401)
    end

    it 'permits admin to view' do
      login_as(admin_user)

      get service_provider_path(sp)

      expect(response.status).to eq(200)
    end
  end
end
