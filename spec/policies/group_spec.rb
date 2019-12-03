require 'rails_helper'

describe GroupPolicy do
  let(:admin_user) { build(:user, admin: true) }
  let(:group_user) { build(:user) }
  let(:other_user) { build(:user) }
  let(:group)      { build(:group) }

  before do
    group.users << group_user
  end

  permissions :create? do
    it 'allows admin users to create' do
      expect(GroupPolicy).to permit(admin_user, group)
    end
  end

  permissions :edit? do
    it 'allows group member or admin to edit' do
      expect(GroupPolicy).to permit(admin_user, group)
      expect(GroupPolicy).to permit(group_user, group)
      expect(GroupPolicy).to_not permit(other_user, group)
    end
  end

  permissions :update? do
    it 'allows group member or admin to update' do
      expect(GroupPolicy).to permit(admin_user, group)
      expect(GroupPolicy).to permit(group_user, group)
      expect(GroupPolicy).to_not permit(other_user, group)
    end
  end

  permissions :new? do
    it 'allows admin user to initiate' do
      expect(GroupPolicy).to permit(admin_user, group)
      expect(GroupPolicy).to_not permit(group_user, group)
      expect(GroupPolicy).to_not permit(other_user, group)
    end
  end

  permissions :destroy? do
    it 'allows admin to destroy' do
      expect(GroupPolicy).to permit(admin_user, group)
      expect(GroupPolicy).to_not permit(group_user, group)
      expect(GroupPolicy).to_not permit(other_user, group)
    end
  end

  permissions :show? do
    it 'allows group member or admin to show' do
      expect(GroupPolicy).to permit(admin_user, group)
      expect(GroupPolicy).to permit(group_user, group)
      expect(GroupPolicy).to_not permit(other_user, group)
    end
  end
end
