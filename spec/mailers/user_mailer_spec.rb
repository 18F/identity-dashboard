require 'rails_helper'

describe UserMailer, type: :mailer do
  let(:app) { create(:application) }

  describe 'user_new_application' do
    let(:mail) { UserMailer.user_new_application(app) }

    it 'sends to app owner' do
      expect(mail.to).to eq [app.user.email]
    end

    it 'renders the subject' do
      expect(mail.subject).to eq t('dashboard.mailer.new_application.subject', id: app.issuer)
    end
  end

  describe 'admin_new_application' do
    let(:mail) { UserMailer.admin_new_application(app) }

    it 'sends to ADMIN_EMAIL' do
      ClimateControl.modify ADMIN_EMAIL: 'identity-admin@example.com' do
        expect(mail.to).to eq ['identity-admin@example.com']
      end
    end

    it 'renders the subject' do
      expect(mail.subject).to eq t('dashboard.mailer.new_application.subject', id: app.issuer)
    end
  end

  describe 'user_approved_application' do
    let(:mail) { UserMailer.user_approved_application(app) }

    it 'sends to app owner' do
      expect(mail.to).to eq [app.user.email]
    end

    it 'renders the subject' do
      expect(mail.subject).to eq t('dashboard.mailer.approved_application.subject', id: app.issuer)
    end
  end

  describe 'admin_approved_application' do
    let(:mail) { UserMailer.admin_approved_application(app) }

    it 'sends to ADMIN_EMAIL' do
      ClimateControl.modify ADMIN_EMAIL: 'identity-admin@example.com' do
        expect(mail.to).to eq ['identity-admin@example.com']
      end
    end

    it 'renders the subject' do
      expect(mail.subject).to eq t('dashboard.mailer.approved_application.subject', id: app.issuer)
    end
  end
end
