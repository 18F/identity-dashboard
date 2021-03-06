require 'rails_helper'

describe UserMailer, type: :mailer do
  let(:app) { create(:service_provider) }

  describe 'user_new_service_provider' do
    let(:mail) { UserMailer.user_new_service_provider(app) }

    it 'sends to app owner' do
      expect(mail.to).to eq [app.user.email]
    end

    it 'renders the subject' do
      expect(mail.subject).to eq t('mailer.new_service_provider.subject', id: app.issuer)
    end
  end

  describe 'admin_new_service_provider' do
    let(:mail) { UserMailer.admin_new_service_provider(app) }

    it 'sends to admin_email' do
      allow(IdentityConfig.store).to receive(:admin_email).and_return('identity-admin@example.com')
    end

    it 'renders the subject' do
      expect(mail.subject).to eq t('mailer.new_service_provider.subject', id: app.issuer)
    end
  end

  describe 'user_approved_service_provider' do
    let(:mail) { UserMailer.user_approved_service_provider(app) }

    it 'sends to app owner' do
      expect(mail.to).to eq [app.user.email]
    end

    it 'renders the subject' do
      expect(mail.subject).to eq t('mailer.approved_service_provider.subject', id: app.issuer)
    end
  end

  describe 'admin_approved_service_provider' do
    let(:mail) { UserMailer.admin_approved_service_provider(app) }

    it 'sends to ADMIN_EMAIL' do
      allow(IdentityConfig.store).to receive(:admin_email).and_return('identity-admin@example.com')
      expect(mail.to).to eq ['identity-admin@example.com']
    end

    it 'renders the subject' do
      expect(mail.subject).to eq t('mailer.approved_service_provider.subject', id: app.issuer)
    end
  end
end
