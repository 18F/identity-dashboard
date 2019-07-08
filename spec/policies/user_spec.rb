require 'rails_helper'

describe UserPolicy do
  let(:admin_user) { build(:user, admin: true) }
  let(:other_user) { build(:user) }
  let(:owner)      { build(:user) }
  let(:user)       { build(:user) }
  let(:app)        { build(:service_provider, user: owner) }

  permissions :create? do
    it 'allows any user to create' do
      expect(ServiceProviderPolicy).to permit(user, app)
    end
  end

  permissions :edit? do
    it 'allows owner to edit' do
      expect(ServiceProviderPolicy).to permit(owner, app)
    end
    it 'allows admin to edit' do
      expect(ServiceProviderPolicy).to permit(admin_user, app)
    end
    it 'does not allow other users to edit' do
      expect(ServiceProviderPolicy).to_not permit(other_user, app)
    end
  end

  permissions :update? do
    it 'allows owner to update' do
      expect(ServiceProviderPolicy).to permit(owner, app)
    end
    it 'allows admin to update' do
      expect(ServiceProviderPolicy).to permit(admin_user, app)
    end
    it 'does not allow other users to update' do
      expect(ServiceProviderPolicy).to_not permit(other_user, app)
    end
  end

  permissions :new? do
    it 'allows any user to initiate' do
      expect(ServiceProviderPolicy).to permit(user, app)
    end
  end

  permissions :destroy? do
    it 'allows owner to destroy' do
      expect(ServiceProviderPolicy).to permit(owner, app)
    end
    it 'allows admin to destroy' do
      expect(ServiceProviderPolicy).to permit(admin_user, app)
    end
    it 'does not allow other users to destroy' do
      expect(ServiceProviderPolicy).to_not permit(other_user, app)
    end
  end

  permissions :show? do
    it 'allows owner to show' do
      expect(ServiceProviderPolicy).to permit(owner, app)
    end
    it 'allows admin to show' do
      expect(ServiceProviderPolicy).to permit(admin_user, app)
    end
    it 'does not allow other users to show' do
      expect(ServiceProviderPolicy).to_not permit(other_user, app)
    end
  end
end
