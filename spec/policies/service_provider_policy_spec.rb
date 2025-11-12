require 'rails_helper'

describe ServiceProviderPolicy do
  let(:logingov_admin) { create(:logingov_admin) }
  let(:team) { create(:team) }
  let(:partner_admin) { create(:team_membership, :partner_admin, team:).user }
  let(:partner_developer) { create(:team_membership, :partner_developer, team:).user }
  let(:partner_readonly) { create(:team_membership, :partner_readonly, team:).user }
  let(:user_not_on_team) { create(:user) }
  let(:config) { create(:service_provider, team:) }

  shared_examples_for 'allows all team members except Partner Readonly for `object`' do
    it 'forbids Partner Readonly' do
      expect(described_class).to_not permit(partner_readonly, object)
    end

    it 'forbids non-team-member users' do
      expect(described_class).to_not permit(user_not_on_team, object)
    end

    it 'allows login.gov admin' do
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
      expect(described_class).to_not permit(user_not_on_team, object)
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

    it 'allows users not on the a team' do
      # Policy scopes ensure they'll only see the service providers they have permissions for
      expect(described_class).to permit(user_not_on_team, ServiceProvider)
    end

    it 'allows anywone without the RBAC flag' do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
      expect(described_class).to permit(user_not_on_team, ServiceProvider)
    end
  end

  permissions :show? do
    it 'forbids non-team-member users' do
      expect(described_class).to_not permit(user_not_on_team, config)
    end

    it 'allows Login Admin' do
      expect(described_class).to permit(logingov_admin, config)
    end

    it 'allows Partner Admin' do
      expect(described_class).to permit(partner_admin, config)
    end

    it 'allows Partner Developer' do
      expect(described_class).to permit(partner_developer, config)
    end

    it 'allows Partner Readonly' do
      expect(described_class).to permit(partner_readonly, config)
    end

    describe 'user owner not in team' do
      it 'allows with RBAC off' do
        config.user = user_not_on_team
        allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
        expect(described_class).to permit(user_not_on_team, config)
      end

      it 'is ignored with RBAC oon' do
        config.user = user_not_on_team
        allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
        expect(described_class).to_not permit(user_not_on_team, config)
      end
    end
  end

  permissions :new? do
    it_behaves_like 'allows all team members except Partner Readonly for `object`' do
      let(:object) { ServiceProvider.new(team:) }
    end

    it 'allows Parter Readonly with RBAC off' do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
      config = ServiceProvider.new(team:)
      expect(described_class).to permit(partner_readonly, config)
    end
  end

  permissions :edit? do
    it_behaves_like 'allows all team members except Partner Readonly for `object`' do
      let(:object) { config }
    end

    describe 'user owner not in team' do
      it 'allows with RBAC off' do
        config.user = user_not_on_team
        allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
        expect(described_class).to permit(user_not_on_team, config)
      end

      it 'is ignored with RBAC on' do
        config.user = user_not_on_team
        allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
        expect(described_class).to_not permit(user_not_on_team, config)
      end
    end

    describe 'status moved_to_prod' do
      before { config.status = 'moved_to_prod' }

      it 'does not allow Login.gov admins to edit' do
        config.user = logingov_admin
        expect(described_class).to_not permit(logingov_admin, config)
      end

      it 'does not allow partner admins to edit' do
        config.user = partner_admin
        expect(described_class).to_not permit(partner_admin, config)
      end
    end
  end

  permissions :destroy? do
    let(:partner_developer_creator) { create(:team_membership, :partner_developer, team:).user }
    let(:partner_developer_noncreator) { create(:team_membership, :partner_developer, team:).user }
    let(:object) { create(:service_provider, team: team, user: partner_developer_creator) }

    before do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
    end

    it 'forbids Partner Readonly' do
      expect(described_class).to_not permit(partner_readonly, object)
    end

    it 'forbids non-team-member users' do
      expect(described_class).to_not permit(user_not_on_team, object)
    end

    it 'allows Login Admin' do
      expect(described_class).to permit(logingov_admin, object)
    end

    it 'allows Partner Admin' do
      expect(described_class).to permit(partner_admin, object)
    end

    it 'allows Partner Developer if they created the configuration' do
      expect(described_class).to permit(partner_developer_creator, object)
    end

    it 'forbids Partner Developer if they did not create the configuration' do
      expect(described_class).to_not permit(partner_developer_noncreator, object)
    end

    describe 'in prod like env' do
      before do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
      end

      it 'allows logingov admin' do
        object.user = logingov_admin
        expect(described_class).to permit(logingov_admin, object)
      end

      it 'forbids everyone else' do
        expect(described_class).to_not permit(partner_developer_creator, object)
        expect(described_class).to_not permit(partner_developer_noncreator, object)
        expect(described_class).to_not permit(user_not_on_team, object)
        expect(described_class).to_not permit(partner_readonly, object)
        expect(described_class).to_not permit(partner_admin, object)
      end
    end

    describe 'user owner not in team' do
      it 'forbids with RBAC off' do
        object.user = user_not_on_team
        allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
        expect(described_class).to_not permit(user_not_on_team, config)
      end

      it 'is ignored with RBAC on' do
        object.user = user_not_on_team
        allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
        expect(described_class).to_not permit(user_not_on_team, config)
      end
    end
  end

  permissions :create? do
    it_behaves_like  'allows all team members except Partner Readonly for `object`' do
      let(:object) { config }
    end

    it 'allows Parter Readonly with RBAC off' do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
      config = ServiceProvider.new(team:)
      expect(described_class).to permit(partner_readonly, config)
    end

    context 'when in a prod-like env' do
      before do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
      end

      it_behaves_like 'allows login.gov admins only for `object`' do
        let(:object) { config }
      end
    end
  end

  permissions :update? do
    it_behaves_like  'allows all team members except Partner Readonly for `object`' do
      let(:object) { config }
    end

    describe 'user owner not in team' do
      it 'allows with RBAC off' do
        config.user = user_not_on_team
        allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
        expect(described_class).to permit(user_not_on_team, config)
      end

      it 'is ignored with RBAC on' do
        config.user = user_not_on_team
        allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
        expect(described_class).to_not permit(user_not_on_team, config)
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
      let(:object) { config }
    end
  end

  permissions :see_status? do
    it_behaves_like 'allows login.gov admins only for `object`' do
      let(:object) { config }
    end
  end

  permissions :prod_request? do
    it_behaves_like  'allows all team members except Partner Readonly for `object`' do
      let(:object) { config }
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
          configroved
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
