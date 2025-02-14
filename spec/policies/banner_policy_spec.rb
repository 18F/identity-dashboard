require 'rails_helper'

RSpec.describe BannerPolicy, type: :policy do
  let(:user) { User.new }
  let(:admin) { User.new(admin: true ) }
  let(:banner) { build(:banner) }
  let(:ended_banner) do
    build(
      :banner,
      start_date: Time.zone.now.beginning_of_day - 2.days,
      end_date: Time.zone.now.beginning_of_day - 1.day,
    )
  end

  subject { described_class }

  permissions '.scope' do
    it 'denies access by default' do
      expect(Pundit.policy_scope!(user, Banner.all)).to eq(Banner.none)
    end
    it 'allows access to admins' do
      expect(Pundit.policy_scope!(admin, Banner.all)).to_not eq(Banner.none)
      expect(Pundit.policy_scope!(admin, Banner.all)).to eq(Banner.all)
    end
  end

  permissions :manage_banners? do
    it 'denies users by default' do
      expect(subject).not_to permit(user, banner)
    end
    it 'allows admins' do
      expect(subject).to permit(admin, banner)
    end
  end

  permissions :edit? do
    it 'denies users by default' do
      expect(subject).not_to permit(user, banner)
    end
    it 'allows admins' do
      expect(subject).to permit(admin, banner)
    end
    it 'denies when banner was displayed in the past' do
      expect(subject).not_to permit(admin, ended_banner)
    end
  end
end
