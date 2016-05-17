require 'rails_helper'

describe ApplicationPolicy do
  permissions :create? do
    it 'allows any user to create' do
      user = build(:user)
      app = build(:application)

      expect(ApplicationPolicy).to permit(user, app)
    end
  end

  permissions :edit? do
    it 'allows owner or admin to edit' do
      user = build(:user)
      other_user = build(:user)
      admin_user = build(:user, admin: true)
      app = build(:application, user: user)

      expect(ApplicationPolicy).to permit(user, app)
      expect(ApplicationPolicy).to permit(admin_user, app)
      expect(ApplicationPolicy).to_not permit(other_user, app)
    end
  end

  permissions :update? do
    it 'allows owner or admin to update' do
      user = build(:user)
      other_user = build(:user)
      admin_user = build(:user, admin: true)
      app = build(:application, user: user)

      expect(ApplicationPolicy).to permit(user, app)
      expect(ApplicationPolicy).to permit(admin_user, app)
      expect(ApplicationPolicy).to_not permit(other_user, app)
    end 
  end

  permissions :new? do
    it 'allows any user to initiate' do
      user = build(:user)
      app = build(:application)

      expect(ApplicationPolicy).to permit(user, app)
    end 
  end

  permissions :destroy? do
    it 'allows owner or admin to destroy' do
      user = build(:user)
      other_user = build(:user)
      admin_user = build(:user, admin: true)
      app = build(:application, user: user)

      expect(ApplicationPolicy).to permit(user, app)
      expect(ApplicationPolicy).to permit(admin_user, app)
      expect(ApplicationPolicy).to_not permit(other_user, app)
    end
  end

  permissions :show? do
    it 'allows owner or admin to show' do
      user = build(:user)
      other_user = build(:user)
      admin_user = build(:user, admin: true)
      app = build(:application, user: user)

      expect(ApplicationPolicy).to permit(user, app)
      expect(ApplicationPolicy).to permit(admin_user, app)
      expect(ApplicationPolicy).to_not permit(other_user, app)
    end
  end
end 
