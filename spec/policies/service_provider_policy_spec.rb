require 'rails_helper'

describe ServiceProviderPolicy do
  let(:app) { create(:service_provider, team:) }

  permissions :index? do
    it 'allows Site Admin' do
      expect(described_class).to permit(site_admin, ServiceProvider)
    end

    it 'allows Partner Admin' do
      expect(described_class).to permit(partner_admin, ServiceProvider)
    end

    it 'allows Partner Developer' do
      expect(described_class).to permit(partner_developer, ServiceProvider)
    end

    it 'allows Partner Readonly' do
      expect(described_class).to permit(partner_readonly, ServiceProvider)
    end

    it 'allows non-team-member users' do
      # Policy scopes ensure they'll only see the service providers they have permissions for
      expect(described_class).to permit(non_team_member, ServiceProvider)
    end

    it 'allows anywone without the RBAC flag' do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
      expect(described_class).to permit(non_team_member, ServiceProvider)
    end
  end

  permissions :show? do
    it 'forbids non-team-member users' do
      expect(described_class).to_not permit(non_team_member, app)
    end

    it 'allows Site Admin' do
      expect(described_class).to permit(site_admin, app)
    end

    it 'allows Partner Admin' do
      expect(described_class).to permit(partner_admin, app)
    end

    it 'allows Partner Developer' do
      expect(described_class).to permit(partner_developer, app)
    end

    it 'allows Partner Readonly' do
      expect(described_class).to permit(partner_readonly, app)
    end

    describe 'user owner not in team' do
      it 'allows with RBAC off' do
        app.user = non_team_member
        allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
        expect(described_class).to permit(non_team_member, app)
      end

      it 'is ignored with RBAC oon' do
        app.user = non_team_member
        allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
        expect(described_class).to_not permit(non_team_member, app)
      end
    end
  end

  permissions :new? do
    it_behaves_like 'allows all team members except Partner Readonly for `object`' do
      let(:object) { ServiceProvider.new(team:) }
    end

    it 'allows Parter Readonly with RBAC off' do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
      app = ServiceProvider.new(team:)
      expect(described_class).to permit(partner_readonly, app)
    end
  end

  permissions :edit? do
    it_behaves_like  'allows all team members except Partner Readonly for `object`' do
      let(:object) { app }
    end

    describe 'user owner not in team' do
      it 'allows with RBAC off' do
        app.user = non_team_member
        allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
        expect(described_class).to permit(non_team_member, app)
      end

      it 'is ignored with RBAC oon' do
        app.user = non_team_member
        allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
        expect(described_class).to_not permit(non_team_member, app)
      end
    end
  end

  permissions :create? do
    it_behaves_like  'allows all team members except Partner Readonly for `object`' do
      let(:object) { app }
    end

    it 'allows Parter Readonly with RBAC off' do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
      app = ServiceProvider.new(team:)
      expect(described_class).to permit(partner_readonly, app)
    end
  end

  permissions :update? do
    it_behaves_like  'allows all team members except Partner Readonly for `object`' do
      let(:object) { app }
    end

    describe 'user owner not in team' do
      it 'allows with RBAC off' do
        app.user = non_team_member
        allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
        expect(described_class).to permit(non_team_member, app)
      end

      it 'is ignored with RBAC oon' do
        app.user = non_team_member
        allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
        expect(described_class).to_not permit(non_team_member, app)
      end
    end
  end

  permissions :all? do
    it_behaves_like 'allows site admins only for `object`' do
      let(:object) { ServiceProvider }
    end
  end

  permissions :deleted? do
    it_behaves_like 'allows site admins only for `object`' do
      let(:object) { ServiceProvider }
    end
  end

  permissions :edit_custom_help_text? do
    it_behaves_like 'allows site admins only for `object`' do
      let(:object) { app }
    end
  end
end

describe ServiceProviderPolicy::Scope do
  let(:user_double) { object_double(build(:user)) }
  let(:test_scope) { object_double(ServiceProvider.all) }

  it 'does not filter when admin' do
    allow(user_double).to receive(:admin?).and_return(true)

    resolution = described_class.new(user_double, test_scope).resolve

    expect(resolution).to be(test_scope)
  end

  it 'filters by user when not admin' do
    intermediary_scope = object_spy(ServiceProvider.all)
    expected_result = ["canary_value_#{rand(1..1000)}"]

    allow(user_double).to receive(:admin?).and_return(false)
    allow(user_double).to receive(:scoped_service_providers)
      .with(scope: test_scope)
      .and_return(intermediary_scope)
    allow(intermediary_scope).to receive(:reorder).with(nil).and_return(expected_result)

    resolution = described_class.new(user_double, test_scope).resolve

    expect(user_double).to have_received(:admin?)
    expect(resolution).to be(expected_result)
  end
end
