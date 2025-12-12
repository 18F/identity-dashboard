require 'rails_helper'

describe TeamPolicy do
  let(:team) { create(:team) }
  let(:other_team) { build(:team) }
  let(:logingov_admin) { create(:logingov_admin) }
  let(:logingov_readonly) { create(:logingov_readonly) }
  let(:partner_admin_user) { create(:team_membership, :partner_admin, team:).user }
  let(:partner_developer_user) { create(:team_membership, :partner_developer, team:).user }
  let(:partner_readonly_user) { create(:team_membership, :partner_readonly, team:).user }
  let(:user_not_on_team) { build(:user) }
  let(:gov_partner) { create(:user, email: 'test@agency.gov') }
  let(:mil_partner) { create(:user, email: 'test@branch.mil') }
  let(:fed_partner) { create(:user, email: 'test@group.fed.us') }
  let(:contractor) { create(:user, email: 'user@contrator.com') }

  permissions :create? do
    it 'allows logingov admins or .gov|mil|fed parters' do
      expect(TeamPolicy).to permit(logingov_admin, team)
      expect(TeamPolicy).to permit(gov_partner, team)
      expect(TeamPolicy).to permit(mil_partner, team)
      expect(TeamPolicy).to permit(fed_partner, team)
    end

    it 'does not allow others' do
      expect(TeamPolicy).to_not permit(contractor, team)
      expect(TeamPolicy).to_not permit(logingov_readonly, team)
    end

    context 'in a prod-like env' do
      before do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
      end

      it 'allows logingov admins' do
        expect(TeamPolicy).to permit(logingov_admin, team)
      end

      it 'forbids everyone else' do
        expect(TeamPolicy).to_not permit(logingov_readonly, team)
      end

      it 'does not allow logingov readonly' do
        expect(TeamPolicy).to_not permit(logingov_readonly, team)
      end

      it 'does not allow other users' do
        expect(TeamPolicy).to_not permit(contractor, team)
      end

      it 'does not allow partners in prod-like envs' do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)

        expect(TeamPolicy).to_not permit(gov_partner, team)
        expect(TeamPolicy).to_not permit(mil_partner, team)
        expect(TeamPolicy).to_not permit(fed_partner, team)
        expect(TeamPolicy).to_not permit(contractor, team)
        expect(TeamPolicy).to_not permit(user_not_on_team, team)
        expect(TeamPolicy).to_not permit(partner_admin_user, team)
        expect(TeamPolicy).to_not permit(partner_developer_user, team)
        expect(TeamPolicy).to_not permit(partner_readonly_user, team)
      end
    end
  end

  permissions :edit? do
    it 'allows partner admins for their team' do
      expect(TeamPolicy).to permit(partner_admin_user, team)
    end

    it 'denies other non-admin team members' do
      expect(TeamPolicy).to_not permit(user_not_on_team, team)
      expect(TeamPolicy).to_not permit(partner_readonly_user, team)
      expect(TeamPolicy).to_not permit(partner_developer_user, team)
    end

    it 'denies access to other teams' do
      expect(TeamPolicy).to_not permit(logingov_readonly, other_team)
      expect(TeamPolicy).to_not permit(partner_admin_user, other_team)
      expect(TeamPolicy).to_not permit(partner_readonly_user, other_team)
      expect(TeamPolicy).to_not permit(partner_developer_user, other_team)
    end

    it 'always allows logingov admins' do
      expect(TeamPolicy).to permit(logingov_admin, team)
      expect(TeamPolicy).to permit(logingov_admin, other_team)
    end
  end

  permissions :update? do
    it 'allows partner admins on the team' do
      expect(TeamPolicy).to permit(partner_admin_user, team)
    end

    it 'forbids users who are not partner admins' do
      expect(TeamPolicy).to_not permit(logingov_readonly, team)
      expect(TeamPolicy).to_not permit(user_not_on_team, team)
      expect(TeamPolicy).to_not permit(partner_readonly_user, team)
      expect(TeamPolicy).to_not permit(partner_developer_user, team)
    end

    it 'forbids partner admins from other teams' do
      expect(TeamPolicy).to_not permit(partner_admin_user, other_team)
    end

    it 'allows logingov admins' do
      expect(TeamPolicy).to permit(logingov_admin, team)
    end
  end

  permissions :new? do
    it 'allows logingov admins or .gov|mil|fed partners' do
      expect(TeamPolicy).to permit(logingov_admin, team)
      expect(TeamPolicy).to permit(gov_partner, team)
      expect(TeamPolicy).to permit(mil_partner, team)
      expect(TeamPolicy).to permit(fed_partner, team)
    end

    it 'does not allow logingov readonly' do
      expect(TeamPolicy).to_not permit(logingov_readonly, team)
    end

    it 'does not allow other users' do
      expect(TeamPolicy).to_not permit(contractor, team)
    end

    it 'does not allow partners in prod-like envs' do
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
      expect(TeamPolicy).to_not permit(gov_partner, team)
      expect(TeamPolicy).to_not permit(mil_partner, team)
      expect(TeamPolicy).to_not permit(fed_partner, team)
      expect(TeamPolicy).to_not permit(contractor, team)
      expect(TeamPolicy).to_not permit(partner_admin_user, team)
      expect(TeamPolicy).to_not permit(partner_developer_user, team)
      expect(TeamPolicy).to_not permit(partner_readonly_user, team)
    end

    it 'does not allow logingov readonly in prod-like envs' do
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
      expect(TeamPolicy).to_not permit(logingov_readonly, team)
    end

    it 'does allow logingov admins in prod-like envs' do
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
      expect(TeamPolicy).to permit(logingov_admin, team)
    end
  end

  permissions :destroy? do
    it 'allows logingov admin' do
      expect(TeamPolicy).to permit(logingov_admin, team)
    end

    it 'forbids logingov readonly' do
      expect(TeamPolicy).to_not permit(logingov_readonly, team)
    end

    it 'forbids partners' do
      expect(TeamPolicy).to_not permit(partner_admin_user, team)
      expect(TeamPolicy).to_not permit(user_not_on_team, team)
      expect(TeamPolicy).to_not permit(partner_readonly_user, team)
      expect(TeamPolicy).to_not permit(partner_developer_user, team)
    end
  end

  permissions :show? do
    it 'allows logingov staff' do
      expect(TeamPolicy).to permit(logingov_admin, team)
      expect(TeamPolicy).to permit(logingov_admin, other_team)
      expect(TeamPolicy).to permit(logingov_readonly, team)
      expect(TeamPolicy).to permit(logingov_readonly, other_team)
    end

    it 'allows partners on the team' do
      expect(TeamPolicy).to permit(partner_readonly_user, team)
      expect(TeamPolicy).to permit(partner_developer_user, team)
      expect(TeamPolicy).to permit(partner_admin_user, team)
    end

    it 'forbids partners on other teams' do
      expect(TeamPolicy).to_not permit(user_not_on_team, team)
      expect(TeamPolicy).to_not permit(partner_readonly_user, other_team)
      expect(TeamPolicy).to_not permit(partner_developer_user, other_team)
      expect(TeamPolicy).to_not permit(partner_admin_user, other_team)
    end
  end

  permissions :all? do
    it 'allows logingov staff' do
      expect(TeamPolicy).to permit(logingov_admin)
      expect(TeamPolicy).to permit(logingov_readonly)
    end

    it 'denies everyone else' do
      expect(TeamPolicy).to_not permit(user_not_on_team)
      expect(TeamPolicy).to_not permit(partner_readonly_user)
      expect(TeamPolicy).to_not permit(partner_developer_user)
      expect(TeamPolicy).to_not permit(partner_admin_user)
    end
  end
end
