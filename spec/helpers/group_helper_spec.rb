require 'rails_helper'
describe GroupHelper do
  let(:user) { build(:user) }
  describe '#can_edit_groups??' do
    it 'returns false if user doesnt have a group' do
      expect(can_edit_groups?(user)).to eq(false)
    end

    it 'returns true if user has a group' do
      user.groups = [create(:group)]
      user.save

      expect(can_edit_groups?(user)).to eq(true)
    end

    it 'returns true if user is an admin' do
      user.admin = true
      user.save

      expect(can_edit_groups?(user)).to eq(true)
    end
  end
end
