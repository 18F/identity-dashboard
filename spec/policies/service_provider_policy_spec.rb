require 'rails_helper'

describe ServiceProviderPolicy do
  let(:admin_user) { create(:admin) }
  let(:other_user) { create(:restricted_ic) }
  let(:owner)      { create(:user) }
  let(:app)        { create(:service_provider, user: owner) }

  permissions :all? do
    it 'allows admin to view' do
      expect(ServiceProviderPolicy).to permit(admin_user, ServiceProvider)
    end

    it 'does not allow an owner to view' do
      expect(ServiceProviderPolicy).to_not permit(owner, ServiceProvider)
    end

    it 'does not allow a random user to view' do
      expect(ServiceProviderPolicy).to_not permit(other_user, ServiceProvider)
    end
  end

  permissions :create? do
    it 'allows admin to create Service Provider' do
      expect(ServiceProviderPolicy).to permit(admin_user, app)
    end

    it 'allows any user to create Service Provider' do
      expect(ServiceProviderPolicy).to permit(other_user, app)
    end

    it 'allows an unrestricted user to create Service Provider' do
      expect(ServiceProviderPolicy).to permit(owner, app)
    end
  end

  permissions :index? do
    it 'allows admin to see an index of Service Providers' do
      expect(ServiceProviderPolicy).to permit(admin_user, app)
    end

    it 'allows any user to see an index of Service Providers' do
      expect(ServiceProviderPolicy).to permit(other_user, app)
    end

    it 'allows an unrestricted user to see an index of Service Providers' do
      expect(ServiceProviderPolicy).to permit(owner, app)
    end
  end

  permissions :member_or_admin? do
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

  permissions :new? do
    it 'allows admin to initiate' do
      expect(ServiceProviderPolicy).to permit(admin_user, app)
    end

    it 'allows any user to initiate' do
      expect(ServiceProviderPolicy).to permit(other_user, app)
    end

    it 'allows an unrestricted user to initiate' do
      expect(ServiceProviderPolicy).to permit(owner, app)
    end
  end
end
