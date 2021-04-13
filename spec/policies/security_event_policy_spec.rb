require 'rails_helper'

RSpec.describe SecurityEventPolicy do
  subject(:policy) { SecurityEventPolicy.new(user, SecurityEvent) }

  describe '#index?' do
    context 'when logged out' do
      let(:user) { nil }

      it 'is false' do
        expect(policy.index?).to eq(false)
      end
    end

    context 'for a non-admin user' do
      let(:user) { build(:user) }

      it 'is true' do
        expect(policy.index?).to eq(true)
      end
    end

    context 'for an admin user' do
      let(:user) { build(:admin) }

      it 'is true' do
        expect(policy.index?).to eq(true)
      end
    end
  end

  describe '#all?' do
    context 'for a non-admin user' do
      let(:user) { build(:user) }

      it 'is false' do
        expect(policy.all?).to eq(false)
      end
    end

    context 'for an admin user' do
      let(:user) { build(:admin) }

      it 'is true' do
        expect(policy.all?).to eq(true)
      end
    end
  end
end
