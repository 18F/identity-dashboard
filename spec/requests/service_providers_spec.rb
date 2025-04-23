require 'rails_helper'

describe 'Users::ServiceProviders' do
  let(:sp) { create(:service_provider, :with_team) }
  let(:user) { create(:user) }
  let(:logingov_admin) { create(:user, :logingov_admin) }
  let(:partner_admin) { create(:user_team, :partner_admin, team: sp.team).user }
  let(:help_text) do
    {
      sign_in: { en: '' },
      sign_up: { en: '' },
      forgot_password: { en: '' },
    }
  end

  describe 'approve on update' do
    it 'disallows app owner from approving the app' do
      login_as(partner_admin)

      put service_provider_path(sp), params: { service_provider: { approved: 'true' } }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'disallows non owner from approving the app' do
      user_on_the_team = create(:user_team, :partner_developer, team: sp.team).user
      login_as(user_on_the_team)

      put service_provider_path(sp), params: { service_provider: { approved: 'true' } }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'allows login.gov admin to approve' do
      login_as(logingov_admin)

      put service_provider_path(sp), params: {
        service_provider: { approved: 'true', help_text: help_text },
      }

      expect(response).to have_http_status(:found) # redirect on success
      sp.reload
      expect(sp.approved).to be(true)
    end
  end

  describe 'view an app' do
    it 'allows Partner Admin to view' do
      login_as(partner_admin)

      get service_provider_path(sp)

      expect(response).to have_http_status(:ok)
    end

    it 'disallows non-owner from viewing' do
      login_as(user)

      get service_provider_path(sp)

      expect(response).to have_http_status(:unauthorized)
    end

    it 'permits login.gov admin to view' do
      login_as(logingov_admin)

      get service_provider_path(sp)

      expect(response).to have_http_status(:ok)
    end
  end
end
