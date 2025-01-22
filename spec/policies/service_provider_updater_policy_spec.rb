require 'rails_helper'

describe ServiceProviderUpdaterPolicy do
  let(:user) { build(:user) }

  permissions :publish? do
    it 'allows any user' do
      expect(described_class).to permit(user)
    end

    it 'forbids without a user' do
      expect(described_class).to_not permit(nil)
    end
  end
end
