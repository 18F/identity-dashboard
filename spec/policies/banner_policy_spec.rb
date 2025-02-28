require 'rails_helper'

RSpec.describe BannerPolicy, type: :policy do
  let(:user) { User.new }
  let(:logingov_admin) { build(:logingov_admin) }
  let(:banner) { build(:banner) }
  let(:ended_banner) do
    build(
      :banner,
      start_date: Time.zone.now.beginning_of_day - 2.days,
      end_date: Time.zone.now.beginning_of_day - 1.day,
    )
  end

  permissions '.scope' do
    it 'denies access by default' do
      expect(Pundit.policy_scope!(user, Banner.all)).to eq(Banner.none)
    end

    it 'allows access to login.gov admins' do
      expect(Pundit.policy_scope!(logingov_admin, Banner.all)).to_not eq(Banner.none)
      expect(Pundit.policy_scope!(logingov_admin, Banner.all)).to eq(Banner.all)
    end
  end

  permissions :manage_banners? do
    it 'denies users by default' do
      expect(described_class).not_to permit(user, banner)
    end

    it 'allows login.gov admins' do
      expect(described_class).to permit(logingov_admin, banner)
    end
  end

  permissions :edit? do
    it 'denies users by default' do
      expect(described_class).not_to permit(user, banner)
    end

    it 'allows login.gov admins' do
      expect(described_class).to permit(logingov_admin, banner)
    end

    it 'denies when banner was displayed in the past' do
      expect(described_class).not_to permit(logingov_admin, ended_banner)
    end
  end
end
