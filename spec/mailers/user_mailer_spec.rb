require 'rails_helper'

describe UserMailer, type: :mailer do
  let(:user) { create(:user) }

  describe 'welcome_new_user' do
    let(:mail) { UserMailer.welcome_new_user(user) }

    it 'sends to user' do
      expect(mail.to).to eq [user.email]
    end

    it 'renders the subject' do
      expect(mail.subject).to eq t('mailer.welcome.subject')
    end
  end
end
