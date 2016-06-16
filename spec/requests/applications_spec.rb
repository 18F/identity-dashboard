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
      ClimateControl.modify ADMIN_EMAIL: 'identity-admin@example.com' do
        app = create(:application)
        admin_user = create(:user, admin: true)
        deliveries.clear
        login_as(admin_user)

        mailer = instance_double(ActionMailer::MessageDelivery)
        allow(UserMailer).to receive(:admin_approved_application).with(anything).and_return(mailer)
        allow(UserMailer).to receive(:user_approved_application).with(anything).and_return(mailer)
        allow(mailer).to receive(:deliver_later)

        put users_application_path(app), application: { approved: 'true' }

        expect(response.status).to eq(302) # redirect on success
        app.reload
        expect(app.approved?).to eq(true)

        expect(UserMailer).to have_received(:admin_approved_application).with(app)
        expect(UserMailer).to have_received(:user_approved_application).with(app)
        expect(mailer).to have_received(:deliver_later).twice
      end
    end
  end

  describe 'notifications' do
    it 'sends email to admin requesting approval' do
      ClimateControl.modify ADMIN_EMAIL: 'identity-admin@example.com' do
        user = create(:user)
        deliveries.clear
        login_as(user)

        mailer = instance_double(ActionMailer::MessageDelivery)
        allow(UserMailer).to receive(:admin_new_application).with(anything).and_return(mailer)
        allow(UserMailer).to receive(:user_new_application).with(anything).and_return(mailer)
        allow(mailer).to receive(:deliver_later)

        post users_applications_path, application: { name: 'test' }

        app = Application.last

        expect(UserMailer).to have_received(:admin_new_application).with(app)
        expect(UserMailer).to have_received(:user_new_application).with(app)
        expect(mailer).to have_received(:deliver_later).twice

        expect(response.status).to eq(302)
        expect(app.approved).to eq(false)
      end
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
