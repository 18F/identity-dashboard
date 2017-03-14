require 'rails_helper'

describe User do
  include MailerSpecHelper

  describe 'Associations' do
    it { should have_many(:service_providers) }
  end

  let(:user) { build(:user) }

  describe '#uuid' do
    it 'assigns uuid on create' do
      user.save
      expect(user.uuid).to_not be_nil
      expect(user.uuid).to match(RubyRegex::UUID)
    end
  end

  describe '#after_create' do
    it 'sends welcome email' do
      deliveries.clear
      expect(deliveries.count).to eq(0)
      user.save
      expect(deliveries.count).to eq(1)
      expect(deliveries.first.subject).to eq(I18n.t('mailer.welcome.subject'))
    end
  end

  describe '#scoped_service_providers' do
    it 'returns user created sps and the users user_group sps' do
      group = create(:user_group)
      user.user_group = group
      user.save
      user_sp = create(:service_provider, user: user)
      group_sp = create(:service_provider, user_group: group)
      create(:service_provider)

      expect(user.scoped_service_providers).to eq([user_sp, group_sp])
    end
  end
end
