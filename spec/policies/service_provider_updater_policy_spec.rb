require 'rails_helper'

describe ServiceProviderUpdaterPolicy do
  let(:user) { build(:user) }

  permissions :publish? do
    it 'allows any user on sandbox envs' do
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return(false)
      expect(described_class).to permit(user)
    end

    it 'forbids all users on prod-like envs' do
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
      expect(described_class).to_not permit(user)
    end

    it 'forbids without a user' do
      expect(described_class).to_not permit(nil)
    end
  end
end
