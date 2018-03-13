require 'rails_helper'

describe 'Users::ServiceProviders' do
  xdescribe 'approve on update' do
    it 'disallows app owner from approving the app' do
      app = create(:service_provider)
      login_as(app.user)

      put service_provider_path(app), service_provider: { approved: 'true' }

      expect(response.status).to eq(401)
    end

    it 'disallows non owner from approving the app' do
      app = create(:service_provider)
      user = create(:user)
      login_as(user)

      put service_provider_path(app), service_provider: { approved: 'true' }

      expect(response.status).to eq(401)
    end

    it 'allows admin to approve' do
      ClimateControl.modify ADMIN_EMAIL: 'identity-admin@example.com' do
        app = create(:service_provider)
        admin_user = create(:user, admin: true)
        deliveries.clear
        login_as(admin_user)

        mailer = instance_double(ActionMailer::MessageDelivery)
        allow(UserMailer).to receive(:admin_approved_service_provider).
          with(anything).and_return(mailer)
        allow(UserMailer).to receive(:user_approved_service_provider).
          with(anything).and_return(mailer)
        allow(mailer).to receive(:deliver_later)

        put service_provider_path(app), service_provider: { approved: 'true' }

        expect(response.status).to eq(302) # redirect on success
        app.reload
        expect(app.approved?).to eq(true)

        expect(UserMailer).to have_received(:admin_approved_service_provider).with(app)
        expect(UserMailer).to have_received(:user_approved_service_provider).with(app)
        expect(mailer).to have_received(:deliver_later).twice
      end
    end
  end

  xdescribe 'notifications' do
    it 'sends email to admin requesting approval' do
      ClimateControl.modify ADMIN_EMAIL: 'identity-admin@example.com' do
        user = create(:user)
        deliveries.clear
        login_as(user)

        mailer = instance_double(ActionMailer::MessageDelivery)
        allow(UserMailer).to receive(:admin_new_service_provider).with(anything).and_return(mailer)
        allow(UserMailer).to receive(:user_new_service_provider).with(anything).and_return(mailer)
        allow(mailer).to receive(:deliver_later)

        post service_providers_path, service_provider: { friendly_name: 'test' }

        app = ServiceProvider.last

        expect(UserMailer).to have_received(:admin_new_service_provider).with(app)
        expect(UserMailer).to have_received(:user_new_service_provider).with(app)
        expect(mailer).to have_received(:deliver_later).twice

        expect(response.status).to eq(302)
        expect(app.approved).to eq(false)
      end
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
      app = create(:service_provider)
      login_as(admin_user)

      get service_provider_path(app)

      expect(response.status).to eq(200)
    end
  end
end
