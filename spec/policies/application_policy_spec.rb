require 'rails_helper'

describe ApplicationPolicy do
  let(:admin_user) { build(:user, admin: true) }
  let(:other_user) { build(:user) }
  let(:owner)      { build(:user) }
  let(:user)       { build(:user) }
  let(:app)        { build(:application, user: owner) }

  permissions :create? do
    it 'allows any user to create' do
      expect(ApplicationPolicy).to permit(user, app)
    end
  end

  permissions :edit? do
    it 'allows owner or admin to edit' do
      expect(ApplicationPolicy).to permit(owner, app)
      expect(ApplicationPolicy).to permit(admin_user, app)
      expect(ApplicationPolicy).to_not permit(other_user, app)
    end
  end

  permissions :update? do
    it 'allows owner or admin to update' do
      expect(ApplicationPolicy).to permit(owner, app)
      expect(ApplicationPolicy).to permit(admin_user, app)
      expect(ApplicationPolicy).to_not permit(other_user, app)
    end
  end

  permissions :new? do
    it 'allows any user to initiate' do
      expect(ApplicationPolicy).to permit(user, app)
    end
  end

  permissions :destroy? do
    it 'allows owner or admin to destroy' do
      expect(ApplicationPolicy).to permit(owner, app)
      expect(ApplicationPolicy).to permit(admin_user, app)
      expect(ApplicationPolicy).to_not permit(other_user, app)
    end
  end

  permissions :show? do
    it 'allows owner or admin to show' do
      expect(ApplicationPolicy).to permit(owner, app)
      expect(ApplicationPolicy).to permit(admin_user, app)
      expect(ApplicationPolicy).to_not permit(other_user, app)
    end
  end
end
