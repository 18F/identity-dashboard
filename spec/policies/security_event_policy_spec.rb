require 'rails_helper'

RSpec.describe SecurityEventPolicy do
  subject(:policy) { SecurityEventPolicy.new(user, model) }

  describe '#index?' do
    let(:model) { SecurityEvent }

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
    let(:model) { SecurityEvent }

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

  describe '#show?' do
    let(:model) { build(:security_event) }

    context 'for a logged out user' do
      let(:user) { nil }

      it 'is false' do
        expect(policy.show?).to eq(false)
      end
    end

    context 'for a non-admin user' do
      let(:user) { build(:user) }

      context 'when the event belongs to the user' do
        let(:model) { build(:security_event, user: user) }

        it 'is true' do
          expect(policy.show?).to eq(true)
        end
      end

      context 'when the event belongs to another user' do
        let(:another_user) { build(:user) }
        let(:model) { build(:security_event, user: another_user) }

        it 'is false' do
          expect(policy.show?).to eq(false)
        end
      end
    end

    context 'for an admin user' do
      let(:user) { build(:admin) }

      it 'is true' do
        expect(policy.show?).to eq(true)
      end
    end
  end
end
