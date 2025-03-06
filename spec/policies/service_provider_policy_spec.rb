require 'rails_helper'

describe ServiceProviderPolicy do
  let(:logingov_admin) { create(:logingov_admin) }
  let(:team) { create(:team) }
  let(:partner_admin) { create(:user_team, :partner_admin, team:).user }
  let(:partner_developer) { create(:user_team, :partner_developer, team:).user }
  let(:partner_readonly) { create(:user_team, :partner_readonly, team:).user }
  let(:non_team_member) { create(:user) }
  let(:app) { create(:service_provider, team:) }

  shared_examples_for 'allows all team members except Partner Readonly for `object`' do
    it 'forbids Partner Readonly' do
      expect(described_class).to_not permit(partner_readonly, object)
    end

    it 'forbids non-team-member users' do
      expect(described_class).to_not permit(non_team_member, object)
    end

    it 'allows Login Admin' do
      expect(described_class).to permit(logingov_admin, object)
    end

    it 'allows Partner Admin' do
      expect(described_class).to permit(partner_admin, object)
    end

    it 'allows Partner Developer' do
      expect(described_class).to permit(partner_developer, object)
    end
  end

  shared_examples_for 'allows login.gov admins only for `object`' do
    it 'allows logingov_admin' do
      expect(described_class).to permit(logingov_admin, object)
    end

    it 'forbids Partner Admin' do
      expect(described_class).to_not permit(partner_admin, object)
    end

    it 'forbids Partner Developer' do
      expect(described_class).to_not permit(partner_developer, object)
    end

    it 'forbids Partner Readonly' do
      expect(described_class).to_not permit(partner_readonly, object)
    end

    it 'forbids non-team-member users' do
      expect(described_class).to_not permit(non_team_member, object)
    end
  end

  permissions :index? do
    it 'allows Login Admin' do
      expect(described_class).to permit(logingov_admin, ServiceProvider)
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

    it 'allows Login Admin' do
      expect(described_class).to permit(logingov_admin, app)
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

      it 'is ignored with RBAC on' do
        app.user = non_team_member
        allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
        expect(described_class).to_not permit(non_team_member, app)
      end
    end
  end

  permissions :all? do
    it_behaves_like 'allows login.gov admins only for `object`' do
      let(:object) { ServiceProvider }
    end
  end

  permissions :deleted? do
    it_behaves_like 'allows login.gov admins only for `object`' do
      let(:object) { ServiceProvider }
    end
  end

  permissions :edit_custom_help_text? do
    it_behaves_like 'allows login.gov admins only for `object`' do
      let(:object) { app }
    end
  end

  describe '#permitted_attributes' do
    before { allow(IdentityConfig.store).to receive(:prod_like_env).and_return(false) }

    context 'when not in prod' do
      it 'allows base attributes for non-admin' do
        subject = described_class.new(build(:user), ServiceProvider)
        expect(subject.permitted_attributes).to eq(described_class::BASE_PARAMS)
      end

      it 'allows extra attributes for login.gov admin' do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
        subject = described_class.new(logingov_admin, ServiceProvider)
        expected_attributes = described_class::BASE_PARAMS + %i[
          email_nameid_format_allowed
          allow_prompt_login
          approved
        ]
        expect(subject.permitted_attributes).to eq(expected_attributes)
      end
    end

    context 'when in prod' do
      before { allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true) }

      it 'allows extra attributes for login.gov admin' do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
        subject = described_class.new(logingov_admin, ServiceProvider)
        expected_attributes = described_class::BASE_PARAMS + %i[
          email_nameid_format_allowed
          allow_prompt_login
          approved
        ]
        expect(subject.permitted_attributes).to eq(expected_attributes)
      end

      it 'forbids editing IAL for non-admin' do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
        subject = described_class.new(build(:user), build(:service_provider, ial: 1))
        expected_attributes = described_class::BASE_PARAMS.reject { |param| param == :ial }
        expect(subject.permitted_attributes).to eq(expected_attributes)
      end
    end
  end
end

describe ServiceProviderPolicy::Scope do
  let(:user_double) { object_double(build(:user)) }
  let(:test_scope) { object_double(ServiceProvider.all) }

  it 'does not filter when login.gov admin' do
    allow(user_double).to receive(:logingov_admin?).and_return(true)

    resolution = described_class.new(user_double, test_scope).resolve

    expect(resolution).to be(test_scope)
  end

  it 'filters by user when not login.gov admin' do
    intermediary_scope = object_spy(ServiceProvider.all)
    expected_result = ["canary_value_#{rand(1..1000)}"]

    allow(user_double).to receive(:logingov_admin?).and_return(false)
    allow(user_double).to receive(:scoped_service_providers)
      .with(scope: test_scope)
      .and_return(intermediary_scope)
    allow(intermediary_scope).to receive(:reorder).with(nil).and_return(expected_result)

    resolution = described_class.new(user_double, test_scope).resolve

    expect(user_double).to have_received(:logingov_admin?)
    expect(resolution).to be(expected_result)
  end
end
