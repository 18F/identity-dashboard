require 'rails_helper'

describe User do
  include MailerSpecHelper

  describe 'Associations' do
    it { should have_many(:service_providers) }
  end

  let(:user) { build(:user) }

  describe '.without_other_user_group' do
    context 'user group id passed in' do
      it 'returns users without a user group or with user group id passed in' do
        _user_in_other_user_group = create(:user, user_group: create(:user_group))
        user_without_group = create(:user)
        users_in_group = create_list(:user, 2)
        user_group = create(:user_group, users: users_in_group)

        expect(User.without_other_user_group(user_group_id: user_group.id)).to match_array(
          users_in_group + [user_without_group],
        )
      end
    end

    context 'no user group id passed in' do
      it 'returns all users without a user group' do
        _user_in_other_user_group = create(:user, user_group: create(:user_group))
        user_without_group = create(:user)

        expect(User.without_other_user_group(user_group_id: nil)).to match_array(
          [user_without_group],
        )
      end
    end
  end

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

  describe '#scoped_user_groups' do
    it 'returns collection of users user groups' do
      group = create(:user_group)
      user.user_group = group
      user.save

      expect(user.scoped_user_groups).to eq([group])
    end

    it 'returns all user groups for admins' do
      2.times do
        create(:user_group)
      end
      user.admin = true
      user.save

      expect(user.scoped_user_groups).to eq(UserGroup.all)
    end
  end
end
