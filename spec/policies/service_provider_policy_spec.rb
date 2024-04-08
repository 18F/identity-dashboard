require 'rails_helper'

describe ServiceProviderPolicy do
  let(:admin_user) { create(:admin) }
  let(:other_user) { create(:restricted_ic) }
  let(:owner)      { create(:ic) }
  let(:app)        { create(:service_provider, user: owner) }

  permissions :create? do
    it 'allows any user to create' do
      expect(ServiceProviderPolicy).to permit(other_user, app)
    end
  end

  permissions :edit? do
    it 'allows owner or admin to edit' do
      expect(ServiceProviderPolicy).to permit(owner, app)
      expect(ServiceProviderPolicy).to permit(admin_user, app)
    end

    it 'does not allow a random user to edit' do
      expect(ServiceProviderPolicy).to_not permit(other_user, app)
    end
  end

  permissions :update? do
    it 'allows owner or admin to update' do
      expect(ServiceProviderPolicy).to permit(owner, app)
      expect(ServiceProviderPolicy).to permit(admin_user, app)
    end

    it 'does not allow a random user to update' do
      expect(ServiceProviderPolicy).to_not permit(other_user, app)
    end
  end

  permissions :new? do
    it 'allows any user to initiate' do
      expect(ServiceProviderPolicy).to permit(other_user, app)
    end
  end

  permissions :destroy? do
    it 'allows owner or admin to destroy' do
      expect(ServiceProviderPolicy).to permit(owner, app)
      expect(ServiceProviderPolicy).to permit(admin_user, app)
    end

    it 'does not allow random user to destroy' do
      expect(ServiceProviderPolicy).to_not permit(other_user, app)
    end

    context 'user is a member of the team' do
      before do
        app.team.users << other_user
      end

      it 'allows user to destroy' do
        expect(ServiceProviderPolicy).to_not permit(other_user, app)
      end
    end
  end

  permissions :show? do
    it 'allows owner or admin to show' do
      expect(ServiceProviderPolicy).to permit(owner, app)
      expect(ServiceProviderPolicy).to permit(admin_user, app)
    end

    it 'does not allow a random user to see the app' do
      expect(ServiceProviderPolicy).to_not permit(other_user, app)
    end
  end
end
