require 'rails_helper'

describe User do
  include MailerSpecHelper

  describe 'Associations' do
    it { should have_many(:service_providers) }
  end

  let(:user) { build(:user) }

  describe '#scoped_service_providers' do
    it 'returns user created sps and the users group sps' do
      group = create(:group)
      user.groups = [group]
      user.save
      user_sp = create(:service_provider, user: user)
      group_sp = create(:service_provider, group: group)
      create(:service_provider)
      expect(user.scoped_service_providers).to eq([user_sp, group_sp])
    end
  end

  describe '#scoped_groups' do
    it 'returns collection of users user groups' do
      group = create(:group)
      user.groups = [group]
      user.save

      expect(user.scoped_groups).to eq([group])
    end

    it 'returns all user groups for admins' do
      2.times do
        create(:group)
      end
      user.admin = true
      user.save

      expect(user.scoped_groups).to eq(Group.all)
    end
  end
end
