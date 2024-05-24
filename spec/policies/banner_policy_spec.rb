require 'rails_helper'

RSpec.describe BannerPolicy, type: :policy do
  let(:user) { User.new }
  let(:admin) { User.new(admin: true )}
  let(:banner) { build(:banner)}

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

  permissions :index?, :show?, :new?, :update? do
    it 'denies users by default' do
      expect(subject).not_to permit(user, banner)
    end
    it 'allows admins' do
      expect(subject).to permit(admin, banner)
    end
  end

  permissions :destroy? do
    it 'is not permitted for anyone' do
      expect(subject).not_to permit(user, banner)
      expect(subject).not_to permit(admin, banner)
    end
  end
end
