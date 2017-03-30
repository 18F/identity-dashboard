require 'rails_helper'
describe UserGroupHelper do
  let(:user) { build(:user) }
  describe '#can_edit_user_groups??' do
    it 'returns false if user doesnt have a user group' do
      expect(can_edit_user_groups?(user)).to eq(false)
    end

    it 'returns true if user has a user group' do
      user.user_group = create(:user_group)
      user.save

      expect(can_edit_user_groups?(user)).to eq(true)
    end

    it 'returns true if user is an admin' do
      user.admin = true
      user.save

      expect(can_edit_user_groups?(user)).to eq(true)
    end
  end
end
