require 'rails_helper'

describe User do
  include MailerSpecHelper

  describe 'Associations' do
    it { should have_many(:service_providers) }
  end

  let(:user) { build(:user) }

  describe '#uuid' do
    it 'does not assign uuid on create' do
      user.save
      expect(user.uuid).to be_nil
    end
  end

  describe '#after_create' do
    it 'does not send welcome email' do
      deliveries.clear
      expect(deliveries.count).to eq(0)
      user.save
      expect(deliveries.count).to eq(0)
    end
  end

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
    it "alphabetizes the list of user created and the user's group sps" do
      group = create(:group)
      user.groups = [group]
      user.save
      sp = {}
      %i[a G c I e].shuffle.each do |prefix|
        sp[prefix.downcase] = create(:service_provider,
                                     user: user, friendly_name: "#{prefix}_service_provider")
      end
      %i[f B h D j].shuffle.each do |prefix|
        sp[prefix.downcase] = create(:service_provider,
                                     group: group, friendly_name: "#{prefix}_service_provider")
      end
      expect(user.scoped_service_providers).to eq(sp.keys.sort.map { |k| sp[k] })
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
